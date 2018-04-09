#!/bin/sh

export LANG=C
set -x

. ./json_dd_reader.sh

SERVER=${1-"192.168.1.73"}
MD5=
FILESIZE=
FILEMODE=

file_info() {
    FILE=$1
    if [ -f ${FILE} ]; then
        MD5=$(cat ${FILE} | md5)
        FILESIZE=$(stat -f%z ${FILE})
        FILEMODE=$(stat -f%p ${FILE})
    fi
}

append_chain() {

    ## note! you only have to escape quotes if what you're sending is a string type, file_meta is a struct, so, 
    ## it expects to parse out the attributes
    ##
    ## RET=$(echo '{"cmd":"append-chain", ... ,"file_meta":{\"name\":\"SomeFileName\",\"mode\":0666}}' | nc ${4} 8089)
    ##

    file_info $4
    RET=$(echo '{
        "cmd":"append-chain",
        "slid":"'${1}'",
        "type":"file",
        "ttl":'${3}',
        "file_meta":{
            "name":"'${4}'",
            "mode":'${FILEMODE}',
            "md5":"'${MD5}'",
            "size":'${FILESIZE}'}}' | nc ${SERVER} 8089)

    json_2_wrt ${RET}
    sh ./TryUpload.q ${WRITER} ${SERVER} ${4}

    file_info $5
    RET=$(echo '{
        "cmd":"append-chain",
        "slid":"'${1}'",
        "type":"file",
        "ttl":'${3}',"file_meta":{
            "name":"'${4}'",
            "mode":'${FILEMODE}',
            "md5":"'${MD5}'",
            "size":'${FILESIZE}'}}' | nc ${SERVER} 8089)

    json_2_wrt ${RET}
    sh ./TryUpload.q ${WRITER} ${SERVER} ${5}

}
fetch_chain() {
    echo '{"cmd":"fetch-chain","slid":"'${1}'"}' | nc ${2} 8089
}
create_chain() {

    KEY=$1
    IDX1=$2
    IDX2=$3
    TTL=$4
    FILE1=$5
    FILE2=$6
    SERVER=$7

    ##
    ##  type BlockMetaRequest struct {
    ##      Name    string  `json:"name"`
    ##      Idx1    string  `json:"idx1"`
    ##      Idx2    string  `json:"idx2"`
    ##      TTL     int     `json:"ttl"`
    ##      Enc     string  `json:"enc_key"`
    ##      Merch   Token   `json:"merchant"`
    ##  }
    ##
    ACCESS=$(echo '{
        "cmd":"create-chain",
        "name":"'${KEY}'",
        "idx1":"'${IDX1}'",
        "idx2":"'${IDX2}'",
        "ttl":'${TTL}'}' | nc ${SERVER} 8089)
    json_2_slid_wrt ${ACCESS}
    echo $SLID
    echo $WRITER
    append_chain "${SLID}" ${WRITER} ${TTL} ${FILE1} ${FILE2} ${SERVER}
    fetch_chain "${SLID}" ${SERVER}
}
create_append_chain() {

    KEY=$1
    IDX1=$2
    IDX2=$3
    TTL=$4
    FILE1=$5
    SERVER=$6

    file_info $FILE1

    RET=$(echo '{
        "cmd":"create-append-chain",
        "block_meta":{
            "name":"'${KEY}'",
            "idx1":"'${IDX1}'",
            "idx2":"'${IDX2}'",
            "ttl":'${TTL}'},
        "payload_meta":{
            "type":"file",
            "ttl":'${TTL}',
            "file_meta":{
                "name":"'${FILE1}'",
                "mode":'${FILEMODE}',
                "md5":"'${MD5}'",
                "size":'${FILESIZE}'}}}' | nc ${SERVER} 8089)

    json_2_oneshot ${RET}
    sh ./TryUpload.q ${WRITER} ${SERVER} ${FILE1}
}
use_matcli() {
    BIN=/Users/bob/work/wintermute/sandboxes/bob/matrix_cli/src/larc.com/matrix_cli/matrix_cli
    IP="--ip=${SERVER}"
    DBG=
    ${BIN}  --block ${DBG} --file=Cnt1to10000 --keywords=JustText --idx1=Engineering --idx2=Test ${IP} ; read SLID
    ${BIN} --append ${DBG} --file=Cnt1to10000 --keywords=JustText --idx1=Engineering --idx2=Test ${IP} --slid="${SLID}"
    ${BIN} --append ${DBG} --file=Cnt1to10000 --keywords=JustText --idx1=Engineering --idx2=Test ${IP} --slid="${SLID}"
    ${BIN} --select ${DBG} --slid="${SLID}" ${IP}
}

## create_chain Counting OneToSomeNum AnotherOneToSomeNum 60 Cnt1to10000 Cnt1to1000 ${SERVER}
## create_append_chain Counting OneToSomeNum AnotherOneToSomeNum 60 Cnt1to10000 ${SERVER}
use_matcli

exit 0
