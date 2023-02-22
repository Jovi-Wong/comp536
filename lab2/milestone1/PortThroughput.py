from scapy.all import Packet, LongField, ShortField

class PortThrouput(Packet):
    name = "portThroughput"
    fields_desc = [ShortField("mark",0),
                   LongField("port2", 0),
                   LongField("port3", 0)]
