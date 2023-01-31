#!/bin/bash
echo "ver1 time"
i=0
while (( $i<10 ))
do
    mytime="$(time ( ./ver1 ) 2>&1 1>/dev/null"
    echo $mytime >> ver1_time.txt
    i=`expr $i + 1`
done

echo "ver2 time"
i=0
while (( $i<10 ))
do
    mytime="$(time ( ./ver2 ) 2>&1 1>/dev/null"
    echo $mytime >> ver2_time.txt
    i=`expr $i + 1`
done