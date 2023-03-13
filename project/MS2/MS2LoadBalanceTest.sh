#!/bin/bash

# MS2 Load balance test. Also implicitly tests ping pong (20 queries, should have 2 ping/pongs)
# Put some values for each switch
python send.py put 0 0
python send.py put 1 1
python send.py put 2 2
python send.py put 513 513
python send.py put 514 514
python send.py put 1023 1023
python send.py put 1024 1024

# Get some values from each switch
python send.py get 0
python send.py get 1023
python send.py get 10
python send.py get 1
python send.py get 1020

# Test range and select from each switch
python send.py range 0 2
python send.py range 10 11
python send.py range 513 514

python send.py select eq 514
python send.py select geq 1023
python send.py select leq 1
python send.py select l 1
python send.py select g 1021