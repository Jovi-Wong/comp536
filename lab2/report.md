# Programmable Network

* Author: Jiawei Wang
* NetID: jw160
* StudentID: S01435302



## Milestone 1

### Task 1

Define the topological structure in the following JSON file named "topology.json".

``` json
{
    "hosts": {
        "h1": {"ip": "10.0.1.1/24", "mac": "00:00:00:00:01:01",
               "commands":["route add default gw 10.0.1.10 dev eth0",
                           "arp -i eth0 -s 10.0.1.10 08:00:00:00:01:00"]},
        "h2": {"ip": "10.0.4.2/24", "mac": "00:00:00:00:04:02",
               "commands":["route add default gw 10.0.2.20 dev eth0",
                           "arp -i eth0 -s 10.0.2.20 08:00:00:00:02:00"]}
    },

    "switches": {
        "s1": {"runtime_json": "./s1-runtime.json"},
        "s2": {"runtime_json": "./s2-runtime.json"},
        "s3": {"runtime_json": "./s3-runtime.json"},
        "s4": {"runtime_json": "./s4-runtime.json"}
    },

    "links":  [
        ["h1", "s1-p1"], ["s1-p2", "s2-p1"], ["s1-p3", "s3-p1"], 
        ["s2-p2", "s4-p1"], ["s3-p2", "s4-p2"], ["s4-p3", "h2"]
    ]
}
```



### Task 2

My implementation is to define a new ethernet type named *TYPE_ECMP* which indicates this packet has not been processed by any switch. Then I change this value to *TYPE_IPV4* after be sent to any port. And I also create three tables in the ingress control block to deal with these headers. In order to send normal packets,  we only need to follow the following scheme.

```shell
sudo python3 ./send.py [address] [message]
```

After the other host is running a receiving program by input the following command.

```shell
sudo python3 ./recv.py
```




### Task 3
To record how many bytes are transmitted through each port at switch 1, I utilize a regsister array as well as a action to manipulate it. Besides, a new ethernet type named 

*TYPE_QURY* is defined. This new type of packet contains 18 bytes in the payload which first 2 bytes are b'\xff\xff' to mark itself and last two 8 bytes to record how many bytes are transmitted through each port. Then I handle this type of packet is the recv.py file by converting it to int and showing the result in the handle_pkt function as following.

```python
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
    sys.stdout.flush()
```

In order to send this special packet, we only need to follow the following scheme.

```shell
sudo python3 ./send.py [address]
```




## Milestone 2

### Task 1





### Task 2



### Task 3

 



## Milestone 3

### Task 1





### Task 2





### Task 3



