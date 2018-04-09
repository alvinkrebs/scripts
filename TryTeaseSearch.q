#!/bin/sh
set -x
set -e
. json_dd_reader.sh

##
## place content with teaser,
## search content using "search-msg"
##
##    type SearchDD struct {
##        Keys string     `json:"keywords"`
##        Idx1 string     `json:"city"`
##        Idx2 string     `json:"state"`
##        Teas string     `json:"teaser"`
##    }
##
##    type SearchResults struct {
##        Key string      `json:"keywords"`
##        Res []string    `json:"results"`
##    }
##
##    type WriteDD struct {
##        Cmd  string     `json:"cmd"`
##        Wrt  string     `json:"writer_token"`
##        Pub  string     `json:"publish"`
##        Data string     `json:"data"`
##        TTL  int        `json:"ttl"`
##        Keys string     `json:"keywords"`
##        Idx1 string     `json:"city"`
##        Idx2 string     `json:"state"`
##        Teas string     `json:"teaser"`
##        Pal  bool       `json:"from_pal"`
##    }
##
##    type ReadDeleteDD struct {
##        Cmd  string     `json:"cmd"`
##        Own  string     `json:"owner_token"`
##    }
##

IP=$1
KEY=$(date +"LA_%s_RC")
ECHO=/bin/echo
GUIDLEN=36
TTL=10

write_msg() {

    Ck=cmd
    Wk=writer_token
    Pk=publish
    Dk=data
    Tk=ttl
    Kk=keywords
    I1k=city
    I2k=state
    TZk=teaser
    C=write-dd

    if [ $# -lt 5 ]; then
        echo "need data (d), ttl (t), keyword (k), index 1 (i1), index 2 (i2), [teaser (tz)]"
        exit 1
    fi

    DD=`echo '{"cmd":"create-dd"}' | nc ${IP} 8089`
    if [ -z ${DD} ]; then
        echo could not create owner/writer ...
        exit 1
    fi
    RET= ; json_2_create_dd ${DD}

    W=$(basename ${RET})
    P=$(dirname ${RET})
    D=$1  ; shift 1
    T=$1  ; shift 1
    K=$1  ; shift 1
    I1=$1 ; shift 1
    I2=$1 ; shift 1
    if [ $# -eq 1 ]; then
        TZ=$1
    else
        TZ=""
    fi

    D="${D} -- Tokens: ${P}/${W}"

    ID=`echo '{
        "'${Ck}'":"'${C}'",
        "'${Pk}'":"'${P}'",
        "'${Tk}'":'${T}',
        "'${Wk}'":"'${W}'",
        "'${Dk}'":"'${D}'",
        "'${Kk}'":"'${K}'",
        "'${I1k}'":"'${I1}'",
        "'${I2k}'":"'${I2}'",
        "'${TZk}'":"'${TZ}'"}' | nc ${IP} 8089`

    if [ -z ${ID} ]; then
        echo message id was not returned ...
        exit 1
    fi

    ## echo "Not to be used in production, but here's the message identifier: ${ID}"

}
read_msg() {

    Ck=cmd
    C=read-entry
    Ok=owner_token

    if [ $# -ne 1 ]; then
        echo "need owner (o)"
        exit 1
    fi

    O=$1

    M=$(echo '{ "'${Ck}'":"'${C}'","'${Ok}'":"'${O}'"}' | nc ${IP} 8089)
    if [ -z ${M} ]; then
        return
    fi

    RET= ; json_2_read_msg $M
    if [ -z ${RET} ]; then
        return
    fi

    MSGS=${RET}
    while [ ${MSGS} != "/" ]; do
        MSG=$(basename ${MSGS})
        MSGS=$(dirname ${MSGS})
        echo ${MSG} | base64 -D
        echo ""
    done

}
search_msg() {

    Ck=cmd
    C=search-msg
    Kk=keywords
    I1k=city
    I2k=state
    TZk=teaser

    if [ $# -lt 3 ]; then
        echo "need keywords (k) index 1 (i1), index 2 (i2), teaser (tz)"
        exit 1
    fi

    K=$1  ; shift 1
    I1=$1 ; shift 1
    I2=$1 ; shift 1
    if [ $# -eq 1 ]; then
        TZ=$1 ; shift 1
    else
        TZ=""
    fi

    SRCH=`echo '{
        "'${Ck}'":"'${C}'",
        "'${Kk}'":"'${K}'",
        "'${I1k}'":"'${I1}'",
        "'${I2k}'":"'${I2}'",
        "'${TZk}'":"'${TZ}'"}' | nc ${IP} 8089`

    if [ -z ${SRCH} ]; then
        echo no search token found ...
        exit 1
    fi

    RET= ; json_2_search_msg ${SRCH}
    if [ -z ${RET} ]; then
        return
    fi

    DDS=$RET
    while [ ${DDS} != "/" ]; do
        DD=$(basename ${DDS})
        DDS=$(dirname ${DDS})
        DDn=$(${ECHO} -n ${DD} | awk '{print length($0);}')
        if [ ${GUIDLEN} -ne ${DDn} ]; then
            break
        fi
        read_msg ${DD}
        if [ -z ${DDS} ]; then
            break
        fi
    done

}

if [ $# -ne 1 ]; then
    echo "need ip address ..."
    exit 1
fi

check_pu() {
    write_msg "${KEY} : Here is some public data ttl ${TTL}, Eng/Photo/Crap Du Bob ..." ${TTL} Eng Photo "Crap Du Bob"
    write_msg "${KEY} : Here is some more public data ttl ${TTL}, Eng/Photo/Crap Du Bob ..." ${TTL} Eng Photo "Crap Du Bob"
    ${ECHO} -n "begin search KEY:${KEY} ... " ; read A
    search_msg Eng Photo "Crap Du Bob"
}

check_pv() {
    ##
    ## key must be unique!! (means only one message per private invite ...)
    ##
    write_msg "${KEY} : Here is some private data ttl ${TTL}, Eng/Photo/Crap Du Bob ..." ${TTL} Eng Photo "Crap Du Bob" ${KEY}
    ${ECHO} -n "begin search KEY:${KEY} ... " ; read A
    search_msg Eng Photo "Crap Du Bob" ${KEY}
}

check_pu
