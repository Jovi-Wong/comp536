/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

#define PKT_INSTANCE_TYPE_NORMAL 0
#define PKT_INSTANCE_TYPE_INGRESS_CLONE 1
#define PKT_INSTANCE_TYPE_EGRESS_CLONE 2
#define PKT_INSTANCE_TYPE_COALESCED 3
#define PKT_INSTANCE_TYPE_INGRESS_RECIRC 4
#define PKT_INSTANCE_TYPE_REPLICATION 5
#define PKT_INSTANCE_TYPE_RESUBMIT 6

const bit<16> TYPE_IPV4 = 0x800;
const bit<8> TYPE_KVSQUERY = 252;
const bit<8> TYPE_TCP = 6;
const bit<16> TYPE_RESPONSE = 0x1234;


/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;
typedef bit<48> ByteCounter_t;
typedef bit<32> PacketCounter_t;
typedef bit<80> PacketByteCounter_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<3>  res;
    bit<3>  ecn;
    bit<6>  ctrl;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

header kvsQuery_t {
    bit<8> protocol;
    bit<32> key;
    bit<32> key2;
    bit<32> value;
    bit<2> switchID;
    bit<2> pingPong;
    bit<2> queryType;
    bit<2> padding;
}

header response_t {
    bit<32> value;
    bit<1> isNull;
    bit<1> nextType;
    bit<6> padding;
}

struct metadata {
    bit<16> ecmp_select;
}

struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    response_t[1025]     response;
    tcp_t        tcp;
    kvsQuery_t   kvsQuery;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ether;
    }

    state parse_ether{
        packet.extract(hdr.ethernet);
        transition select (hdr.ethernet.etherType){
            TYPE_RESPONSE: parse_response;
            default: accept;
        }
    }

    state parse_response {
        packet.extract(hdr.response.next); 
        transition select(hdr.response.last.nextType) {
            1: parse_ipv4; // last header in the header stack
            0: parse_response; // parse the next header
            default: accept;
        }
    }

    state parse_ipv4{
        packet.extract(hdr.ipv4);
        transition select (hdr.ipv4.protocol) {
            TYPE_TCP: parse_tcp;
            TYPE_KVSQUERY: parse_kvsQuery;
            default: accept;
        }
    }

    state parse_kvsQuery{
        packet.extract(hdr.kvsQuery);
        transition select (hdr.kvsQuery.protocol) {
            TYPE_TCP: parse_tcp;
            default: accept;
        }
    }

    state parse_tcp{
        packet.extract(hdr.tcp);
        transition accept;
    }
}


/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {   
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    register <bit<32>>(2) requestCounts; // 0: number of requests (if 10), 1: number of requests (if 15)
    register <bit<32>>(2) pingPongCounts1;// Switch 1, 0: count of pings, 1: count of pongs
    register <bit<32>>(2) pingPongCounts2;// Switch 2, 0: count of pings, 1: count of pongs

    apply {
        if (hdr.response[0].isValid()) {
            // forward traffic
            if (standard_metadata.ingress_port == 1){
                // Issue a ping for every 10th request
                bit<32> numRequest = 0;
                requestCounts.read(numRequest, 0);
                if (numRequest == 9) {
                    // Clear request count
                    requestCounts.write(0, 0);
                    // Update ping count
                    bit<32> pingCount = 0;
                    pingPongCounts1.read(pingCount, 0);
                    pingPongCounts1.write(0, pingCount + 1);
                    pingPongCounts2.read(pingCount, 0);
                    pingPongCounts2.write(0, pingCount + 1);
                    // Send ping to both backend switches
                    clone(CloneType.I2E, 2);
                    hdr.kvsQuery.pingPong = 0;
                } else {
                    // Put requests also get sent to standby switch
                    if (hdr.kvsQuery.queryType == 1) {
                        clone(CloneType.I2E, 1);
                    }
                    hdr.kvsQuery.pingPong = 0;
                    // Update request count
                    requestCounts.write(0, numRequest + 1);
                }
                // load balancing
                if (hdr.kvsQuery.key >= 0 && hdr.kvsQuery.key <= 512){
                    standard_metadata.egress_spec = 2;
                } else if (hdr.kvsQuery.key > 512 && hdr.kvsQuery.key <= 1024){
                    standard_metadata.egress_spec = 3;
                }
            } 
            // returning traffic
            else {
                // Check Ping and Pong counts for every 15th request
                bit<32> numRequest = 0;
                requestCounts.read(numRequest, 1);
                bit<32> pingCount1 = 0;
                bit<32> pongCount1 = 0;
                bit<32> pingCount2 = 0;
                bit<32> pongCount2 = 0;
                pingPongCounts1.read(pingCount1, 0);
                pingPongCounts1.read(pongCount1, 1);
                pingPongCounts2.read(pingCount2, 0);
                pingPongCounts2.read(pongCount2, 1);
                // Update pong count
                if (hdr.kvsQuery.pingPong == 2) {
                    if (hdr.kvsQuery.switchID == 1){
                        pongCount1 = pongCount1 + 1;
                        pingPongCounts1.write(1, pongCount1); 
                    } else if (hdr.kvsQuery.switchID == 2) {
                        pongCount2 = pongCount2 + 1;
                        pingPongCounts2.write(1, pongCount2); 
                    }
                } else if (numRequest == 14) {
                    if (pingCount1 - pongCount1 > 10) {
                        // Failure bound is 10 ping/pongs difference
                        hdr.kvsQuery.pingPong = 3;
                    }
                    if (pingCount2 - pongCount2 > 10) {
                        // Failure bound is 10 ping/pongs difference
                        hdr.kvsQuery.pingPong = 3;
                    }
                    requestCounts.write(1, 0);
                } else {
                    // Update request count
                    requestCounts.write(1, numRequest + 1);
                }
                standard_metadata.egress_spec = 1; 
            }
        }
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {  
        // Send pings for any cloned packets
        if (standard_metadata.instance_type == PKT_INSTANCE_TYPE_INGRESS_CLONE) {
            hdr.kvsQuery.pingPong = 1;
        }
    }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
     apply {
	update_checksum(
	    hdr.ipv4.isValid(),
            { hdr.ipv4.version,
	      hdr.ipv4.ihl,
              hdr.ipv4.diffserv,
              hdr.ipv4.totalLen,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);
    }
}


/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.response);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.kvsQuery);
        packet.emit(hdr.tcp);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
