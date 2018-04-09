#!/bin/sh

## set -x

if [ $# -lt 2 ]; then
    echo usage owner_token outputfile server delete readall
    exit 1
fi

OWNER=${1}
TARGET=${2-${OWNER}.`date "+%Y%m%d%H%M%S"`}
IP=${3-"luke.larcnetworks.com"}
DELETE=${4-"false"}
READALL=${5-"false"}
echo '{"cmd":"stream-entry","owner_token":"'${OWNER}'","read_all":'${READALL}',"delete":'${DELETE}'}' | nc ${IP} 8089 > ${TARGET}
