/* INCLUDES */
#include <cores.p4>
#include <v1model.p4>

/* HEADERS */
typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

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

struct ecmp_t {
    bit<8>    isFirstHop;
}

struct metadata {}

struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    ecmp_t       ecmp;
}

/* PARSER */
parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {
    state start {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4: parse_ipv4;
            default: acctpt;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition parse_ecmp;
    }

    state parse_ecmp {
        packet.extract(hdr.ecmp);
        transition acctpt;
    }
}

/* VERIFICATION */
control MyVerification(inout headers hdr, inout metadata meta) {
    apply {  }
}

/* INGRESS */
control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    action set_random_port(bit<16> base, bit<32> cnt) {
        hash(standard_metadata.egress_spec,
            HashAlgorithm.crc16,
            base,
            { 
                hdr.ipv4.srcAddr,
                hdr.ipv4.dstAddr,
                hdr.ipv4.protocol
            },
            cnt);
    }

    action drop() {
        mark_to_drop(standard_metadata);
    }

    table ecmp_port {
        key = {hdr.ipv4.dstAddr: exact;}
        actions = 
        {
            set_random_port;
            drop;
            NoAction;
        }
        default_action = "drop";
    }

    action ecmp_forward(macAddr_t dstAddr) {
        hdr.ecmp = 0;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    table ecmp_table {
        key = { standard_metadata.egressPort: exact; }
        actions = {
            ecmp_forward;
            NoAction;
        }
        size = 32;
        default_action = NoAction();
    }

    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {
        standard_metadata.egress_spec = port;
        hdr.ethernet.dstAddr = dstAddr;
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
        default_action = drop();
    }

    apply {
        if (hdr.ecmp.isFirstHop == 0) {
            ipv4_table.apply();
        } else {
            ecmp_port.apply();
            ecmp_table.apply();
        }
    }
}

/* EGRESS */
control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    
    action rewrite_mac(bit<48> smac) {
        hdr.ethernet.srcAddr = smac;
    }
    action drop() {
        mark_to_drop(standard_metadata);
    }
    table send_frame {
        key = {
            standard_metadata.egress_port: exact;
        }
        actions = {
            rewrite_mac;
            drop;
        }
        size = 256;
    }
    apply {
        send_frame.apply();
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
    }
}

/* SWITCH */
V1Switch(
    MyParser(),
    MyVerifyChecksum(),
    MyIngress(),
    MyEgress(),
    MyComputeChecksum(),
    MyDeparser()
) main;