#!/bin/bash

# Tests that error cases with queries are handled correctly and gracefully

# First put some values in
python send.py put 200 200
python send.py put 200 400
python send.py put 201 201

# Try to put to some invalid places (don't fulfill)
python send.py put 1025 0
python send.py put 2000 2000

# Put to a key more than 6 times (don't fulfill 6th request)
python send.py put 100 100
python send.py put 100 101
python send.py put 100 102
python send.py put 100 103
python send.py put 100 104
python send.py put 100 105
python send.py put 100 106

# Make sure the versions are still correct after putting 6 times
python send.py get 100 0
python send.py get 100 1
python send.py get 100 2
python send.py get 100 3
python send.py get 100 4
python send.py get 100 5

# Get a version number that isn't put yet
python send.py get 200 3
python send.py get 201 1

# Use an illegal version number (don't fulfill)
python send.py get 100 7

# Out-of-range get (don't fulfill)
python send.py get 1030 0
python send.py get 2000 0

# Range queries, some values, some null
python send.py range 100 102 2
python send.py range 200 202 1

# Range queries, all null
python send.py range 240 243 0

# Illegal range queries (don't fulfill)
python send.py range 1023 1028 0
python send.py range 5 1 0
python send.py range 100 102 10

# Illegal predicates for select (don't fulfill)
python send.py select l 0 0
python send.py select g 1024 0
python send.py select geq 1030 1
python send.py select eq 1050 0

# Select test with versioning
python send.py select eq 200 1
python send.py select eq 100 4
python send.py select eq 201 2