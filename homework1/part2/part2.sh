#!/bin/bash
echo "ver1 time"
i=0
while (( $i<1000 ))
do
    /usr/bin/time ./ver1 > ./ver1_time.txt
    i=`expr $i + 1`
done

echo "ver2 time"
i=0
while (( $i<1000 ))
do
    /usr/bin/time ./ver2 > ./ver2_time.txt
    i=`expr $i + 1`
done