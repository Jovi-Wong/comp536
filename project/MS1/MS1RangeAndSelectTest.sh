#!/bin/bash

# Test ranges
python send.py range 0 3 0
python send.py range 222 223 0
python send.py range 1022 1025 0

# Test all select predicates
python send.py select geq 1023 0 
python send.py select l 2 0
python send.py select leq 0 0
python send.py select g 1020 0
python send.py select eq 1024 0
