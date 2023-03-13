#!/usr/bin/env python
import sys
import struct
import os
import logging

logging.getLogger("scapy.runtime").setLevel(logging.ERROR)

from scapy.all import sniff, sendp, hexdump, get_if_list, get_if_hwaddr
from scapy.all import Packet, IPOption
from scapy.all import ShortField, IntField, LongField, BitField, FieldListField, FieldLenField
from scapy.all import IP, TCP, UDP, Ether, Raw
from scapy.layers.inet import _IPOption_HDR
from scapy.all import BitField, ShortField, IntField, bind_layers

QUERY_PROTOCOL = 250
KVSQUERY_PROTOCOL = 252
TCP_PROTOCOL = 6
RESPONSE_PROTOCOL = 0x1234

# Packet used to send request information for the query
class KVSQuery(Packet):
    name = "KVSQuery"
    fields_desc= [BitField("protocol", 0, 8),
                IntField("key", 0),
                IntField("key2", 0),
                IntField("value", 0),
                IntField("versionNum", 0),
                BitField("switchID", 0, 2),                
                BitField("pingPong", 0, 2),
                BitField("queryType", 0, 2),
                BitField("padding", 0, 2)]

# Packet used to return query results as a response header
class Response(Packet):
    name = "Response"
    fields_desc= [IntField("value", 0),
                BitField("isNull", 0, 1),
                BitField("nextType", 0, 1),
                BitField("padding", 0, 6)]

bind_layers(Ether, Response, type=RESPONSE_PROTOCOL)
bind_layers(Response, Response, nextType = 0)
bind_layers(Response, IP, nextType = 1)
bind_layers(IP, KVSQuery, proto = KVSQUERY_PROTOCOL)
bind_layers(KVSQuery, TCP, protocol = TCP_PROTOCOL)

def get_if():
    ifs=get_if_list()
    iface=None
    for i in get_if_list():
        if "eth0" in i:
            iface=i
            break;
    if not iface:
        print "Cannot find eth0 interface"
        exit(1)
    return iface

class IPOption_MRI(IPOption):
    name = "MRI"
    option = 31
    fields_desc = [ _IPOption_HDR,
                    FieldLenField("length", None, fmt="B",
                                  length_of="swids",
                                  adjust=lambda pkt,l:l+4),
                    ShortField("count", 0),
                    FieldListField("swids",
                                   [],
                                   IntField("", 0),
                                   length_from=lambda pkt:pkt.count*4) ]

# Helper function used retrieve packet layers
def get_packet_layers(packet):
    counter = 0
    while True:
        layer = packet.getlayer(counter)
        if layer is None:
            break

        yield layer
        counter += 1

def handle_pkt(pkt):
    if KVSQuery in pkt and pkt[KVSQuery].padding == 1:
        # Display get request results
        if pkt[KVSQuery].queryType == 0:
            if pkt[Response].isNull == 0:
                print "NULL"
            else:
                print pkt[Response].value
        # Display put request results
        elif pkt[KVSQuery].queryType == 1:
            if pkt[Response].isNull == 1:
                print "Unable to store value. Too many versions."
            else:
                print 'Value stored.'
        # Display range and select request results by reading each header stack layer
        elif pkt[KVSQuery].queryType == 2:
            for layer in reversed(list(get_packet_layers(pkt))):
                if layer.name == "Response" and layer.nextType == 0:
                    if layer.isNull == 0:
                        print "NULL"
                    else:
                        print layer.value
            # print pkt.summary()
        print "------------------------"
        sys.stdout.flush()




def main():
    ifaces = filter(lambda i: 'eth' in i, os.listdir('/sys/class/net/'))
    iface = ifaces[0]
    print "sniffing on %s" % iface
    sys.stdout.flush()
    sniff(iface = iface,
          prn = lambda x: handle_pkt(x))

if __name__ == '__main__':
    main()
