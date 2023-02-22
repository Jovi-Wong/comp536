import os
import sys

from scapy.all import FieldLenField, FieldListField, IntField, IPOption, ShortField, get_if_list, sniff
from scapy.layers.inet import _IPOption_HDR

from PortThroughput import PortThrouput

def get_if():
    iface=None
    for i in get_if_list():
        if "eth0" in i:
            iface=i
            break
    if not iface:
        print("Cannot find eth0 interface")
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
def handle_pkt(pkt):
    print("got a packet")
    pkt.show2()
    msg = pkt["TCP"].payload.load

    if len(msg) == 18 and msg[0:2] == b'\xff\xff':
        mark = msg[0:2]
        port2_throughput = int.from_bytes(msg[2:10], "big")
        port3_throughput = int.from_bytes(msg[10:18], "big")
        print("mark = {0}".format(mark))
        print("Port2 = {0} bytes and Port3 = {1} bytes in total!".format(port2_throughput, port3_throughput))
#    hexdump(pkt)
    sys.stdout.flush()


def main():
    ifaces = [i for i in os.listdir('/sys/class/net/') if 'eth' in i]
    iface = ifaces[0]
    print("sniffing on %s" % iface)
    sys.stdout.flush()
    sniff(filter="tcp", iface = iface, prn = lambda x: handle_pkt(x))

if __name__ == '__main__':
    main()
