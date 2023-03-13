#!/bin/bash

# Testing some generic puts
python send.py put 0 1
python send.py put 1 2
python send.py put 2 3
python send.py put 3 4

# Testing some generic gets without testing versioning
python send.py get 0 0
python send.py get 1 0
python send.py get 2 0
python send.py get 3 0

# Put some other values
python send.py put 1024 369
python send.py put 1023 258

python send.py get 1024 0
python send.py get 1023 0
python send.py get 1022 0
python send.py get 512 0
