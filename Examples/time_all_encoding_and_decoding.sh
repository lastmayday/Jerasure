#!/usr/bin/sh

METHODS=("reed_sol_van" "reed_sol_r6_op" "cauchy_orig" "cauchy_good" "liberation" "blaum_roth" "liber8tion" "evenodd")
ITERATIONS=5
BUFSIZE=65536
PACSIZE=2048
FILE="/home/lastmayday/Pictures/7dd98d1001e939012694ccd07aec54e737d1964d.jpg"
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

    t1=0
    t2=0
    for i in `seq $ITERATIONS`; do
        res=`./encoder ${FILE} ${k} ${m} ${method} ${w} ${PACSIZE} ${BUFSIZE}`
        encode=$(echo $res | awk -F ' ' '{print $3}')
        t1=$(echo $t1 $encode | awk '{ printf "%f", $1 + $2 }')
        en_total=$(echo $res | awk -F ' ' '{print $6}')
        t2=$(echo $t2 $en_total | awk '{ printf "%f", $1 + $2 }')
    done
    encode=$(echo $t1 $ITERATIONS | awk '{ printf "%f", $1 / $2 }')
    en_total=$(echo $t2 $ITERATIONS | awk '{ printf "%f", $1 / $2 }')
    echo "Encoding (MB/sec): $encode"
    echo "En_Total (MB/sec): $en_total"

    rm ${rm_file1} ${rm_file2}

    t1=0
    t2=0
    for i in `seq $ITERATIONS`; do
        res=`./decoder "$file_name.$file_ext"`
        decode=$(echo $res | awk -F ' ' '{print $3}')
        t1=$(echo $t1 $decode | awk '{ printf "%f", $1 + $2 }')
        de_total=$(echo $res | awk -F ' ' '{print $6}')
        t2=$(echo $t2 $de_total | awk '{ printf "%f", $1 + $2 }')
    done
    decode=$(echo $t1 $ITERATIONS | awk '{ printf "%f", $1 / $2 }')
    de_total=$(echo $t2 $ITERATIONS | awk '{ printf "%f", $1 / $2 }')
    echo "Decoding (MB/sec): $decode"
    echo "De_Total (MB/sec): $de_total"

done
