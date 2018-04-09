#!/bin/sh

if [ $# -lt 3 ]; then
    echo "Usage: TrySoak.q <ip address> <zip code> <question> <answer> [<luke writer dd>]"
    exit 1
fi

## set -x
set -e
ECHO=/bin/echo
VEGAS=luke.larcnetworks.com
FWD=
IP=$1 ; shift 1
Z=$1  ; shift 1
Q=$1  ; shift 1
A=$1  ; shift 1

if [ $# -eq 1 ]; then
    FWD=$1
else
    ## if we weren't passed a forwarding DD assume we want to create a new pair ...
    ##
    OW=$(echo '{"cmd":"create-dd"}' | nc ${VEGAS} 8089 | perl -ne 'use JSON;
        print decode_json($_)->{'owner_token'}, "/", decode_json($_)->{'writer_token'};')

    FWD=$(basename ${OW})

    echo "Seek will read $(dirname ${OW})"
    echo "You will write to ${FWD}"

fi

## send qna to the local cube
##
echo '{"cmd":"index-question","zip":'${Z}',"question":"'${Q}'","answer":"'${A}'","ttl":1440}' | nc ${IP} 8089 > /dev/null

## send qna to luke, prepend question with owner token
##
Q=${FWD}-${Q}

echo '{"cmd":"index-question","zip":'${Z}',"question":"'${Q}'","answer":"'${A}'","ttl":1440}' | nc ${VEGAS} 8089 > /dev/null

${ECHO} -n "Question: ${Q}, "

echo '{"cmd":"index-answer","zip":'${Z}',"question":"'${Q}'"}' | nc ${VEGAS} 8089 | perl -ne 'use JSON;
    $idx = 0;
    foreach $answer ( @{decode_json($_)} ) {
        if ($idx++ == 0) {
            printf("owner is %s ...\n", $answer->{'owner'});
        }
        printf("\t[%02d]: %-32s -- %s\n", $idx, $answer->{'expires'}, $answer->{'answer'});
    }'

exit 0
