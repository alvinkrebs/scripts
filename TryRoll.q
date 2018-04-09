#!/bin/sh

IP=${1-192.168.200.166}
main() {
    EC=/bin/echo
    ttl=30
    msgNum=1
    writer=""
    GRN="[97;42m"
    RED="[97;41m"
    echo "Server: $IP"
    ##
    ## Green initiates a message ... Initialization of Green --> Red
    ##
    message="Hello Red, this is green ... 1 ..."
    ${EC} ${GRN}'{"cmd":"write-roll","writer_token":"'${writer}'","message":"'"${message}"'","ttl":'${ttl}'}'
    rwr=`echo '{"cmd":"write-roll","writer_token":"'${writer}'","message":"'"${message}"'","ttl":'${ttl}'}' | nc ${IP} 8089 |
            perl -ne 'use JSON; print decode_json($_)->{'reader_token'},"/",decode_json($_)->{'writer_token'},"/",decode_json($_)->{'response_token'};'`

    ${EC} ""
    grn_reader=`basename $rwr` && rwr=`dirname $rwr`
    red_writer=`basename $rwr` && rwr=`dirname $rwr`
    red_reader=`basename $rwr` && rwr=`dirname $rwr`
    ${EC} "red_reader: ${red_reader}, red_writer: ${red_writer}, grn_reader: ${grn_reader}"
    resp

    while [ $ttl -gt 10 ];
    do
        ##
        ## Red fetches message and responds back to green ... Red --> Green
        ##
        ${EC} ${RED}'{"cmd":"read-roll","reader_token":"'${red_reader}'"}'
        ${EC} '{"cmd":"read-roll","reader_token":"'${red_reader}'"}' | nc ${IP} 8089
        ${EC} ""
        resp

        ttl=`expr $ttl - 5`
        msgNum=`expr $msgNum + 1`
        message="Hello Green, this is red ... ${msgNum}  ..."
        ${EC} '{"cmd":"write-roll","writer_token":"'${red_writer}'","message":"'"${message}"'","ttl":'${ttl}'}'
        rwr=`${EC} '{"cmd":"write-roll","writer_token":"'${red_writer}'","message":"'"${message}"'","ttl":'${ttl}'}' | nc ${IP} 8089 |
            perl -ne 'use JSON; print decode_json($_)->{'reader_token'}, "/", decode_json($_)->{'writer_token'};'`
        ${EC} ""
        red_reader=`dirname $rwr`
        grn_writer=`basename $rwr`
        ${EC} "red_reader: ${red_reader}, grn_writer: ${grn_writer}"
        resp

        ##
        ## Green fetches message and responds back to red ... Green --> Red
        ##
        ${EC} ${GRN}'{"cmd":"read-roll","reader_token":"'${grn_reader}'"}'
        ${EC} '{"cmd":"read-roll","reader_token":"'${grn_reader}'"}' | nc ${IP} 8089
        resp
        ${EC} ""

        ttl=`expr $ttl - 5`
        msgNum=`expr $msgNum + 1`
        message="Hello Red, this is green ... $msgNum ..."
        ${EC} '{"cmd":"write-roll","writer_token":"'${grn_writer}'","message":"'"${message}"'","ttl":'${ttl}'}'
        rwr=`${EC} '{"cmd":"write-roll","writer_token":"'${grn_writer}'","message":"'"${message}"'","ttl":'${ttl}'}' | nc ${IP} 8089 |
            perl -ne 'use JSON; print decode_json($_)->{'reader_token'}, "/", decode_json($_)->{'writer_token'};'`
        ${EC} ""
        grn_reader=`dirname $rwr`
        red_writer=`basename $rwr`
        ${EC} "grn_reader: ${grn_reader}, red_writer: ${red_writer}"
        resp
    done

    exit 0
}

resp() {
    if [ 1 != 1 ]; then
        ${EC} -n "continue ... "
        read A
        ${EC} .
    fi
}

main
