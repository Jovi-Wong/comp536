#!/bin/bash
i=0
while (( $i<1000 ))
do
    mytime="$(/usr/bin/time ./ver1 2>&1 1>/dev/null)"
    echo $mytime >> ver1_time.txt
    i=`expr $i + 1`
done

i=0
while (( $i<1000 ))
do
    mytime="$(/usr/bin/time ./ver2 2>&1 1>/dev/null)"
    echo $mytime >> ver2_time.txt
    i=`expr $i + 1`
done