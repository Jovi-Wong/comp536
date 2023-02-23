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

And the result is shown as below.

![m1t3](D:\Documents\GitHub\comp536\lab2\asset\m1t3.PNG)






## Milestone 2

### Task 1

I have send 100 packets from h1 to h2 with payload range from 1 to 100. And the result shows that the port2 of switch1 transmits 4565 bytes and port3 of switch2 transmits 5885 bytes in total.

<img src="D:\Documents\GitHub\comp536\lab2\asset\m2t1-lb.PNG" alt="m2t1-lb" style="zoom:100%;" />

I have written and test all scripts, so you only need to run

```shell
sudo python3 ./send.py
```

on host1 after run

```shell
sudo python3 ./recv.py
```

on host2. And it is also true for all following tasks.



### Task 2

In order to achieve per-packet flow control, I replace the hash function with a register holding the index of previous port for message transmission. And the result of this policy shows that the port2 of switch1 transmits 5250 bytes and port3 of switch2 transmits 5200 bytes in total. This result is much better than the previous one.



![m2t2-lb](D:\Documents\GitHub\comp536\lab2\asset\m2t2-lb.PNG)



### Task 3

 I set the path via switch 2 with latency 110ms and 10ms to the other path. Besides, I choose the global inversions mentioned in the leetcode 775 as the approach to count out-of-ordered packets.

![m2t3](D:\Documents\GitHub\comp536\lab2\asset\m2t3.PNG)

As result, there are 61 out-of-order packets in total.



## Milestone 3

### Task 1

To implement the flowlet switching, I set 10ms latency to the route via switch2 and 110ms latency to the route via switch3. Hence, the $\delta = 100$ms which indicates we need to change egress port every 100ms. I use a register to hold the current egress port and an extra register named firstPktTime to hold the ingress time of the first packet in the current burst. When a new packet comes in, we will compare its timestamp with the firstPktTime to determine whether change the egress port or not.



### Task 2

The result of experiment posted below shows that the flowlet switching is 29.5% less than the per-packet switching in packet reordering. But it is about 1% more than the per-packet switching in inbalance. 

![m3t1](D:\Documents\GitHub\comp536\lab2\asset\m3t1.PNG)

In short, the flowlet switching combines the best of the per-packet switching and the per-flow switching.

