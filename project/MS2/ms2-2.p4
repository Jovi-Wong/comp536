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

    register <bit<32>>(512) database;
    register <bit<1>>(512) isFilled;

    // Setting the egress port and IP destination.
    action set_nhop(bit<32> nhop_ipv4, bit<9> port) {
        hdr.ipv4.dstAddr = nhop_ipv4;
        standard_metadata.egress_spec = port;
        //hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    action drop() {
        mark_to_drop(standard_metadata);
    }

    action get() {
        // Read database value associated with the key into the top response header stack
        database.read(hdr.response[0].value, hdr.kvsQuery.key - 513);
        // Check isFilled register to ensure key-value pair exists
        isFilled.read(hdr.response[0].isNull, hdr.kvsQuery.key - 513);
    }

    action put() {
        // Write database value given key
        database.write(hdr.kvsQuery.key - 513, hdr.kvsQuery.value);
        isFilled.write(hdr.kvsQuery.key - 513, 1);
    }

    action rangeGet() {
        // Push a new header to the response header stack
        hdr.response.push_front(1);
        hdr.response[0].setValid();
        // Perform get operation
        database.read(hdr.response[0].value, hdr.kvsQuery.key - 513);
        isFilled.read(hdr.response[0].isNull, hdr.kvsQuery.key - 513);
        // Increment key for next recirculation
        hdr.kvsQuery.key = hdr.kvsQuery.key + 1;
    }

    table Forwarding {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            drop;
            set_nhop;
        }
    }

    table Ops {
        key = {
            hdr.kvsQuery.queryType: exact;
            hdr.kvsQuery.pingPong: exact;
        }
        actions = {
            drop;
            get;
            put;
            rangeGet;
            NoAction;
        }
        default_action = NoAction();
    }

    apply {
    	if (hdr.response[0].isValid()) {
            Ops.apply();
            hdr.kvsQuery.padding = 1;
            hdr.kvsQuery.switchID = 2;
            // Report pong if packet is a ping
            if (hdr.kvsQuery.pingPong == 1) {
                hdr.kvsQuery.pingPong = 2;
            }
            
            // Recirculate only for ranges and non-ping packets
            if (hdr.kvsQuery.queryType == 2 && hdr.kvsQuery.pingPong != 2) {
            	if (hdr.kvsQuery.key < hdr.kvsQuery.key2){
            		// clone(CloneType.I2E, 1);
            		recirculate(meta);
            	}
            }
            Forwarding.apply();
        }
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {  }
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
