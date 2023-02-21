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

My implementation is to define a new ethernet type named *TYPE_ECMP* which indicates this packet has not been processed by any switch. Then I change this value to *TYPE_IPV4* after be sent to any port.



### Task 3









## Milestone 2

### Task 1





### Task 2



### Task 3

 



## Milestone 3

### Task 1





### Task 2





### Task 3



