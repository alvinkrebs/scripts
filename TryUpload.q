#!/bin/sh

GIVEUP=
if [ $(uname) = "Linux" ]; then
    GIVEUP="-q 5"
fi

## set -x
if [ $# -lt 5 ]; then
    echo usage server ttl writer_token index file
    exit 1
fi
IP=${1}     ; shift 1
TTL=${1}    ; shift 1
WRITER=${1} ; shift 1
IDX=${1}    ; shift 1
FILE=$@
##
## TryUpload.q <server> <ttl> <writer token> <index> <filename>
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
Content-Disposition: form-data; name="index"

${IDX}
--LARCLARCLARCLARCLARCLARCLARCLARCLA

hdr
## 
## ATTACH the file
##
if [ -d "${FILE}" ]; then 
    for i in "${FILE}"/"*"
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
