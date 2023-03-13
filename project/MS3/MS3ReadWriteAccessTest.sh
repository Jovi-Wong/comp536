#!/bin/bash

# Legal writes for Alice
python sendA.py put 0 0
python sendA.py put 10 10
python sendA.py put 300 300
python sendA.py put 512 512

# Legal writes for Bob
python sendB.py put 1 1
python sendB.py put 10 11
python sendB.py put 200 200

# Illegal writes for Alice
python sendA.py put 513 513
python sendA.py put 1024 1024

# Illegal writes for Bob
python sendB.py put 257 257
python sendB.py put 1024 1024
python sendB.py put 511 511

# Legal reads for Alice
python sendA.py get 0
python sendA.py get 10
python sendA.py get 513
python sendA.py range 300 302
python sendA.py range 1023 1024
python sendA.py select leq 1
python sendA.py select eq 1024

# Legal reads for Bob
python sendB.py get 1
python sendB.py get 200
python sendB.py range 0 2
python sendB.py select l 1
python sendB.py select eq 200

# Illegal reads for Bob
python sendB.py get 300
python sendB.py get 1020
python sendB.py range 512 513
python sendB.py range 253 258
python sendB.py select geq 1020
