#!/bin/sh

#set -x
set -e
. json_dd_reader.sh

IP=$1

search_msgs() {

    Ck=cmd
    Ik=andex
    C=search-msg

    K=$1
    Ik=$2

    if [ $# -lt 1 ]; then
        echo "need keys (k)"
        exit 1
    fi

    ID=`echo '{"'${Ck}'":"'${C}'","'${Ik}'":'${K}'}' | nc ${IP} 8089`

    echo $ID

}
write_msg() {

    Ck=cmd
    Wk=writer_token
    Dk=data
    Tk=ttl
    Ik=index
    C=write-dd

    T=$1
    D=$2
    K=$3

    if [ $# -lt 2 ]; then
        echo "need data (d), ttl (t)"
        exit 1
    fi

    DD=`echo '{"cmd":"create-dd"}' | nc ${IP} 8089`
    if [ -z ${DD} ]; then
        echo could not create owner/writer ...
        exit 1
    fi
    RET= ; json_2_create_dd ${DD}
    W=$(basename ${RET})

    ID=`echo '{
        "'${Ck}'":"'${C}'",
        "'${Wk}'":"'${W}'",
        "'${Dk}'":"'${D}'",
        "'${Tk}'":'${T}',
        "'${Ik}'":'${K}'}' | nc ${IP} 8089`
}
##search_msgs '["a","g","h"]' andex
##exit 0

TooFew='["a","b","c","d","e","f"]'
TooMany='["a","b","c","d","e","f","g","h","i"]'
JustRight='["a","b","c","d","e","f","g","h"]'

write_msg 10 "Message" ${TooFew}
write_msg 10 "Message" ${TooMany}
write_msg 10 "Message" ${JustRight}

search_msgs ${TooFew} index
search_msgs '["","b"]' index
search_msgs '["a","b"]' index
search_msgs '["a","g","h"]' index

search_msgs ${TooFew} andex
search_msgs '["","b"]' andex
search_msgs '["a","b"]' andex
search_msgs '["a","g","h"]' andex
search_msgs '["a","g","h","z"]' andex
