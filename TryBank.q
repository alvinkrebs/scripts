#!/bin/sh

json_2_mxid_owner() {
    RET=$(echo $* | perl -ne 'use JSON; print decode_json($_)->{'owner'}')
}

get_amount_by_owner() {
    BAL=$(echo '{"cmd":"account-balance","source":"'${1}'"}' | nc ${HOST} 8089)
    RET=$(echo $BAL | perl -ne 'use JSON; print decode_json($_)->{'amount'}')
}

SRC=${1-"Bear"}
DST=${2-"Woodson"}
HOST=${3-"banana"}

RET=$(echo '{"cmd":"matrix-id-exists","matrix_name":"'${SRC}'"}'  | nc ${HOST} 8089)
json_2_mxid_owner ${RET}
OW_SRC=${RET}

RET=$(echo '{"cmd":"matrix-id-exists","matrix_name":"'${DST}'"}' | nc ${HOST} 8089)
json_2_mxid_owner ${RET}
OW_DST=${RET}

## these will work once, after that, the server rejects the request
##
echo '{"cmd":"create-account","source":"'${OW_SRC}'","amount":100}' | nc ${HOST} 8089
echo '{"cmd":"create-account","source":"'${OW_DST}'","amount":100}' | nc ${HOST} 8089

## check balance
##
## echo '{"cmd":"account-balance","source":"'${OW_SRC}'"}' | nc ${HOST} 8089 && echo ""
## echo '{"cmd":"account-balance","source":"'${OW_DST}'"}' | nc ${HOST} 8089 && echo ""
get_amount_by_owner ${OW_SRC} && echo "${SRC} = ${RET}"
get_amount_by_owner ${OW_DST} && echo "${DST} = ${RET}"

## some transacations ...
##
echo '{"cmd":"post-transaction","source":"'${OW_SRC}'","destination":"'${OW_DST}'","amount":5}' | nc ${HOST} 8089
echo '{"cmd":"post-transaction","source":"'${OW_SRC}'","destination":"'${OW_DST}'","amount":5}' | nc ${HOST} 8089
echo '{"cmd":"post-transaction","source":"'${OW_SRC}'","destination":"'${OW_DST}'","amount":5}' | nc ${HOST} 8089
echo '{"cmd":"post-transaction","source":"'${OW_SRC}'","destination":"'${OW_DST}'","amount":5}' | nc ${HOST} 8089
