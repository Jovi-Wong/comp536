from scapy.all import Packet, LongField

class PortThrouput(Packet):
    name = "portThroughput"
    fields_desc = [LongField("port2", 0),
                   LongField("port3", 0)]
