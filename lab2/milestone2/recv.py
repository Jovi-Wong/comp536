import os
import sys

from scapy.all import get_if_list, sniff
# from scapy.layers.inet import _IPOption_HDR

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

recv_pkt_ids = []
    
def handle_pkt(pkt):
    print("got a packet")
    pkt.show2()

    msg = pkt["TCP"].payload.load
    print(pkt["TCP"].seq)
    recv_pkt_ids.append(pkt["TCP"].seq)
    if len(msg) == 18 and msg[0:2] == b'\xff\xff':
        port2_throughput = int.from_bytes(msg[2:10], "big")
        port3_throughput = int.from_bytes(msg[10:18], "big")
        print("\nPort2 = {0} bytes and Port3 = {1} bytes in total!".format(port2_throughput, port3_throughput))
#    hexdump(pkt)
    sys.stdout.flush()

def count_out_of_order_pkt(ids):
    n = len(ids)
    ans = 0
    for i in range(n):
        for j in range(i+1,n):
            if ids[i] > ids[j]:
                ans += 1
    return ans

def main():
    ifaces = [i for i in os.listdir('/sys/class/net/') if 'eth' in i]
    iface = ifaces[0]
    print("sniffing on %s" % iface)
    sys.stdout.flush()
    sniff(filter="tcp", iface = iface, prn = lambda x: handle_pkt(x))
    print("Unordered packets number = {0}".format(count_out_of_order_pkt(recv_pkt_ids)))

if __name__ == '__main__':
    main()
