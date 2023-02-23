import random
import socket
import sys
from scapy.all import IP, TCP, Ether, get_if_hwaddr, get_if_list, sendp

from PortThroughput import PortThrouput

def get_if():
    iface=None # "h1-eth0"
    for i in get_if_list():
        if "eth0" in i:
            iface=i
            break
    if not iface:
        print("Cannot find eth0 interface")
        exit(1)
    return iface

def main():
    addr = socket.gethostbyname(sys.argv[1])
    iface = get_if()
    for i in range(100):
        pkt = Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff', type=0x3814) / IP(dst=addr) / TCP(dport=1234, sport=random.randint(49152,65535), seq=i) / ("a"*(i+1))
        sendp(pkt, iface=iface, verbose=False)

    pkt = Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff', type=0x9723) / IP(dst=addr) / TCP(dport=1234, sport=random.randint(49152,65535)) / PortThrouput()
    sendp(pkt, iface=iface, verbose=False)

if __name__ == '__main__':
    main()