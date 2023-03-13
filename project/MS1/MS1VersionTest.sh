#!/bin/bash

# Add some versions
python send.py put 10 10
python send.py put 10 20
python send.py put 10 30
python send.py put 10 40
python send.py put 10 50
python send.py put 10 60

python send.py put 11 11
python send.py put 11 22
python send.py put 11 33

python send.py put 12 12
python send.py put 12 24

python send.py put 13 13

# Get some versions
python send.py get 10 1
python send.py get 10 3
python send.py get 10 5
python send.py get 11 0
python send.py get 11 2
python send.py get 12 5
python send.py get 13 1

# Test range with versions
python send.py range 10 14 0
python send.py range 10 14 1
python send.py range 10 15 2

# Test select with versions
python send.py select eq 12 1
python send.py select eq 10 0
