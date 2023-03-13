#!/bin/bash

python receive.py > MS1TestOutput.out &
source MS1GetAndPutTest.sh
source MS1RangeAndSelectTest.sh
source MS1VersionTest.sh
source MS1ErrorTest.sh
sleep 1
pkill -9 -f receive.py
python TestUtil.py
