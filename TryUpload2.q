#!/bin/sh

GIVEUP=
if [ $(uname) = "Linux" ]; then
    GIVEUP="-q 5"
fi
## set -x
set -e
if [ $# -lt 4 ]; then
    echo usage server ttl writer_token file
    exit 1
fi
IP=${1}     ; shift 1
TTL=${1}    ; shift 1
WRITER=${1} ; shift 1
FILE=$@
if [ $(uname) = "Linux" ]; then
    SIZE=$(stat -c%s "${FILE}")
else
    SIZE=$(stat -f "%z" "${FILE}")
fi
cat<<hdr>out.$$
${SIZE} ${TTL} ${WRITER}
hdr
cat "${FILE}" >> out.$$
cat out.$$ | nc ${GIVEUP} ${IP} 8090
rm out.$$
