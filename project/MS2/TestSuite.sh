#!/bin/bash

python receive.py > MS2TestOutput.out &
source MS2LoadBalanceTest.sh
sleep 1
pkill -9 -f receive.py
python TestUtil.py
