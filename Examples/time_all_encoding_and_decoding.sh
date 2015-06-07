#!/usr/bin/env bash

# METHODS=("reed_sol_van" "reed_sol_r6_op" "cauchy_orig" "cauchy_good" "evenodd")
BUFSIZE=(1024 4096 16384 65536 262144 \
         1048576 4194304 16777216 67108864  268435456 \
         1073741824)
METHODS=("cauchy_good")
ITERATIONS=10
PACSIZE=2048
FILE="/home/huangdi/Documents/bigfile.tmp"
k=5
m=2
w=8

filename=$(basename "$FILE")
file_ext="${filename##*.}"
file_name="${filename%.*}"
file_base="Coding/"

rm_file1="$file_base$file_name""_k2.$file_ext"
rm_file2="$file_base$file_name""_k4.$file_ext"

for method in "${METHODS[@]}"; do
    echo ${method}
    if [ ${method} = "evenodd" ]; then
        w=1
    elif [ ${method} = "liberation" ]; then
        w=7
    elif [ ${method} = "blaum_roth" ]; then
        w=6
    else
        w=8
    fi

    for buffer in "${BUFSIZE[@]}"; do
        echo ${buffer}
        t1=0
        for i in `seq ${ITERATIONS}`; do
            res=`./encoder ${FILE} ${k} ${m} ${method} ${w} ${PACSIZE} ${buffer}`
            encode=$(echo $res | awk -F ' ' '{print $3}')
            t1=$(echo $t1 $encode | awk '{ printf "%f", $1 + $2 }')
        done
        encode=$(echo $t1 $ITERATIONS| awk '{ printf "%f", $1 / $2 / 1024 }')
        echo "Encoding (G/sec): $encode"

        rm ${rm_file1} ${rm_file2}
        t1=0
        for i in `seq ${ITERATIONS}`; do
            res=`./decoder "$file_name.$file_ext"`
            decode=$(echo $res | awk -F ' ' '{print $3}')
            t1=$(echo $t1 $decode | awk '{ printf "%f", $1 + $2 }')
        done
        decode=$(echo $t1 $ITERATIONS| awk '{ printf "%f", $1 / $2 / 1024}')
        echo "Decoding (G/sec): $decode"
    done
    echo

done
