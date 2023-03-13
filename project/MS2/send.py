#!/usr/bin/env python
import argparse
import sys
import socket
import random
import struct
import string
import time
import logging

logging.getLogger("scapy.runtime").setLevel(logging.ERROR)

from scapy.all import sendp, send, get_if_list, get_if_hwaddr
from scapy.all import Packet
from scapy.all import Ether, IP, UDP, TCP, Raw
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
    iface=None # "h1-eth0"
    for i in get_if_list():
        if "eth0" in i:
            iface=i
            break;
    if not iface:
        print "Cannot find eth0 interface"
        exit(1)
    return iface


# Helper to split the current range by the size, and send multiple range requests
def splitRange(addr, iface, lower, upper, size = 10):
    if upper > 1025 or lower > 1025 or upper < 0 or lower < 0 or lower > upper:
        print 'invalid value'
        exit(1)

    i = lower
    while i < upper - size:
        pkt = Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff', type=RESPONSE_PROTOCOL)
        pkt = pkt / Response(nextType = 1)
        pkt = pkt / IP(dst=addr, proto=KVSQUERY_PROTOCOL) / KVSQuery(protocol=TCP_PROTOCOL, queryType=2, key=i, key2=i+size)
        # for j in range(4):
        #     pkt = pkt / Response(nextType = 0)
        pkt = pkt / TCP(dport=1234, sport=random.randint(49152,65535)) / "range"
        sendp(pkt, iface=iface, verbose=False)
        # print (i, "to", i + size)
        i += size

    pkt = Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff', type=RESPONSE_PROTOCOL)
    pkt = pkt / Response(nextType = 1)
    pkt = pkt / IP(dst=addr, proto=KVSQUERY_PROTOCOL) / KVSQuery(protocol=TCP_PROTOCOL, key=i, key2=upper, queryType=2)
    # for j in range(i, upper - 1):
    #      pkt = pkt / Response(nextType = 0)
    pkt = pkt / TCP(dport=1234, sport=random.randint(49152,65535)) / "range"
    sendp(pkt, iface=iface, verbose=False)
    # print (i, "to", upper)

def main():
    # if len(sys.argv)<3:
    #     print 'pass 2 arguments: <destination> "<message>"'
    #     exit(1)

    if len(sys.argv) < 2:
        print 'pass 1 argument:"<ops>"'
        exit(1)

    # Specific IP for Switch 1 entrance
    addr = '10.0.1.1'
    iface = get_if()

    print "sending on interface %s to %s" % (iface, str(addr))

    # Handle and send get request
    if sys.argv[1] == "get":
        if len(sys.argv) < 3:
            print 'pass 1 more argument:"<key>"'
            exit(1)
        if int(sys.argv[2]) > 1025 or int(sys.argv[2]) < 0:
            print 'invalid value'
            exit(1)
        pkt = Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff', type=RESPONSE_PROTOCOL)
        pkt = pkt / Response(nextType = 1)
        pkt = pkt / IP(dst=addr, proto=KVSQUERY_PROTOCOL) / KVSQuery(protocol=TCP_PROTOCOL, queryType=0, key=int(sys.argv[2])) / TCP(dport=1234, sport=random.randint(49152,65535)) / "get"
        # pkt.show2()
        sendp(pkt, iface=iface, verbose=False)   
    # Handle and send put request       
    elif sys.argv[1] == "put":
        if len(sys.argv) < 4:
            print 'pass 2 more arguments:"<key>" "<value>"'
            exit(1)
        if int(sys.argv[2]) > 1024 or int(sys.argv[2]) < 0:
            print 'invalid value'
            exit(1)
        pkt = Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff', type=RESPONSE_PROTOCOL)
        pkt = pkt / Response(nextType = 1)
        pkt = pkt / IP(dst=addr, proto=KVSQUERY_PROTOCOL) / KVSQuery(protocol=TCP_PROTOCOL, queryType=1, key=int(sys.argv[2]), value=int(sys.argv[3])) / TCP(dport=1234, sport=random.randint(49152,65535)) / "put"
        sendp(pkt, iface=iface, verbose=False)   
    # Handle and send range request 
    elif sys.argv[1] == "range":
        if len(sys.argv) < 4:
            print 'pass 2 more arguments:"<key1>" "<key2>"'
            exit(1)
        splitRange(addr, iface, int(sys.argv[2]), int(sys.argv[3]))
    # Handle and send select request 
    elif sys.argv[1] == "select":
        if len(sys.argv) < 4:
            print 'pass 2 more arguments:"<operand>" "<key>"'
            exit(1)

        upper = 0
        lower = 0
        if sys.argv[2] == "g":
            if int(sys.argv[3]) >= 1024:
                print 'invalid value'
                exit(1)
            upper = 1025
            lower = int(sys.argv[3]) + 1
        elif sys.argv[2] == "geq":
            upper = 1025
            lower = int(sys.argv[3])
        elif sys.argv[2] == "l":
            if int(sys.argv[3]) <= 0:
                print 'invalid value'
                exit(1)
            upper = int(sys.argv[3])
            lower = 0
        elif sys.argv[2] == "leq":
            upper = int(sys.argv[3]) + 1
            lower = 0
        elif sys.argv[2] == "eq":
            upper = int(sys.argv[3]) + 1
            lower = int(sys.argv[3])
        splitRange(addr, iface, lower, upper)

if __name__ == '__main__':
    main()
