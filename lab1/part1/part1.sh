#!/bin/bash
i=0
while (( $i<1000 ))
do
    ./prog >> task1.out
    i=`expr $i + 1`
done

cnt=1
f1_first_cnt=0
f2_first_cnt=0
cat task1.out | while read file
do
    if (( $cnt%2==1 ))
    then
        if [ $file = "f1" ]
        then
            f1_first_cnt=`expr $f1_first_cnt + 1`
        else
            f2_first_cnt=`expr $f2_first_cnt + 1`
        fi
    fi
    cnt=`expr $cnt + 1`
    echo "f1_first_cnt = ${f1_first_cnt}, f2_first_cnt = ${f2_first_cnt}"
done