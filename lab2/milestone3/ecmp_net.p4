/* INCLUDES */
#include <core.p4>
#include <v1model.p4>

/* HEADERS */
typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

const bit<16> TYPE_ECMP = 0x3814;
const bit<16> TYPE_IPV4 = 0x0800;
const bit<16> TYPE_QURY = 0x9723;

const bit<32> REG_PORT2 = 0x0000;
const bit<32> REG_PORT3 = 0x0001;

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

header len_t {
    bit<16> mark;
    bit<64> p2Count;
    bit<64> p3Count;
}

struct metadata {}

struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    tcp_t        tcp;
    len_t        lens;
}

/* PARSER */
parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ether;
    }
    
    state parse_ether {
        packet.extract(hdr.ethernet);
        transition parse_ipv4;
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition parse_tcp;
    }

    state parse_tcp {
        packet.extract(hdr.tcp);
        transition parse_qury;
    }

    state parse_qury {
        packet.extract(hdr.lens);
        transition accept;
    }
}

/* VERIFICATION */
control MyVerification(inout headers hdr, inout metadata meta) {
    apply {  }
}


/* INGRESS */

register<bit<48>>(1) firstPktTime;
register<bit<9>>(1) curPort;

action set_curPort(in bit<9> N,
                   inout standard_metadata_t stdmeta) {
    bit<48> lastTime;
    firstPktTime.read(lastTime, 0);
    bit<48> timeDiff = stdmeta.ingress_global_timestamp - lastTime;
    curPort.read(stdmeta.egress_spec, 0);
    if (timeDiff > 100000) {
        stdmeta.egress_spec = (stdmeta.egress_spec + 1) % N + 2;
    }
}

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    action drop() {
        mark_to_drop(standard_metadata);
    }

    action ecmp_forward(macAddr_t dstAddr) {
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    table ecmp_table {
        key = { standard_metadata.egress_spec: exact; }
        actions = {
            ecmp_forward;
            NoAction;
        }
        size = 32;
    }

    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {
        hdr.ethernet.dstAddr = dstAddr;
        standard_metadata.egress_spec = port;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    table ipv4_table {
        key = { hdr.ipv4.dstAddr: exact; }
        actions = 
        {
            ipv4_forward;
            drop;
        }
        size = 32;
    }

    apply {
        if (hdr.ethernet.etherType == TYPE_IPV4) {
            ipv4_table.apply();
        } else if (hdr.ethernet.etherType == TYPE_ECMP) {
            set_curPort(2, standard_metadata);
            ecmp_table.apply();
        } else if (hdr.ethernet.etherType == TYPE_QURY) {
            set_curPort(2, standard_metadata);
            ecmp_table.apply();
        }
    }
}

/* EGRESS */
register<bit<64>>(2) portCounter;

action portCounterCalc(in bit<32> pktLen,
                    in bit<9> port,
                    out bit<64> port1Counter,
                    out bit<64> port2Counter){
    
    bit<64> len_sum;
    portCounter.read(len_sum, (bit<32>)port);
    bit<64> new_len_sum = len_sum + (bit<64>)pktLen;
    portCounter.write((bit<32>)port, new_len_sum);
    portCounter.read(port1Counter, REG_PORT2);
    portCounter.read(port2Counter, REG_PORT3);
}

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {
        if (hdr.ethernet.etherType == TYPE_ECMP) {
            hdr.ethernet.etherType = TYPE_IPV4;
            bit<64> counter1;
            bit<64> counter2;
            portCounterCalc(standard_metadata.packet_length, standard_metadata.egress_port-2, counter1, counter2);
        } else if (hdr.ethernet.etherType == TYPE_QURY) {
            hdr.ethernet.etherType = TYPE_IPV4;
            hdr.lens.mark = 0xffff;
            bit<64> counter1;
            bit<64> counter2;
            portCounterCalc(0, standard_metadata.egress_port-2, counter1, counter2);
            hdr.lens.p2Count = counter1;
            hdr.lens.p3Count = counter2;
        }
    }
}



/* COMPUTATION */
control MyComputation(inout headers hdr,
                      inout metadata meta) {
    apply {
        update_checksum(
	    hdr.ipv4.isValid(), {
        hdr.ipv4.version,
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

/* DEPARSER */
control MyDeparser(packet_out packet, 
                   in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
        packet.emit(hdr.lens);
    }
}

/* SWITCH */
V1Switch(
    MyParser(),
    MyVerification(),
    MyIngress(),
    MyEgress(),
    MyComputation(),
    MyDeparser()
) main;