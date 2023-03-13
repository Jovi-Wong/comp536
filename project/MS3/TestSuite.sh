#!/bin/bash

python receive.py > MS3TestOutput.out &
source MS3ReadWriteAccessTest.sh
source MS3RateLimitTest.sh
sleep 1
pkill -9 -f receive.py
python TestUtil.py
