#!/bin/sh
## set -x
. ./json_dd_reader.sh

GIVEUP=
if [ $(uname) = "Linux" ]; then
    GIVEUP="-q 5"
fi

## set -x
if [ $# -lt 6 ]; then
    echo usage server file key idx1 idx2 ttl
    exit 1
fi

echo $2

IP=${1}
FILE=${2}
KEY=${3}
IDX1=${4}
IDX2=${5}
TTL=${6}

DD=`echo '{"cmd":"create-dd"}' | nc ${IP} 8089`
if [ -z ${DD} ]; then
    echo could not create owner/writer ...
    exit 1
fi
RET= ; json_2_create_dd ${DD}

WRITER=$(basename ${RET})
READER=$(dirname ${RET})

echo "Reader: ${READER}"

##
## TryPublish.q <writer token> <server> <filename> <reader_token> <key> <idx1> <idx2>
##
## HEADER that contains the writer token
##
cat<<hdr>out.$$
Content-Type: multipart/form-data; boundary=LARCLARCLARCLARCLARCLARCLARCLARCLA

--LARCLARCLARCLARCLARCLARCLARCLARCLA
Content-Disposition: form-data; name="writer_token"

${WRITER}
--LARCLARCLARCLARCLARCLARCLARCLARCLA
Content-Disposition: form-data; name="ttl"

${TTL}
--LARCLARCLARCLARCLARCLARCLARCLARCLA
Content-Disposition: form-data; name="publish"

${READER}
--LARCLARCLARCLARCLARCLARCLARCLARCLA
Content-Disposition: form-data; name="keywords"

${KEY}
--LARCLARCLARCLARCLARCLARCLARCLARCLA
Content-Disposition: form-data; name="city"

${IDX1}
--LARCLARCLARCLARCLARCLARCLARCLARCLA
Content-Disposition: form-data; name="state"

${IDX2}
--LARCLARCLARCLARCLARCLARCLARCLARCLA

hdr
## 
## ATTACH the file
##
if [ -d "${FILE}" ]; then 
    for i in "${FILE}"/*
    do
        echo $i >> out.$$
        cat $i  >> out.$$
    done
else
    cat "${FILE}" >> out.$$
fi
## 
## FOOTER 
##
cat<<ftr>>out.$$

--LARCLARCLARCLARCLARCLARCLARCLARCLA--
ftr
##
## SEND
##
cat out.$$ | nc ${GIVEUP} ${IP} 8090
rm out.$$
