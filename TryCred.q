#!/bin/sh

# Turn off debugging for now ..
#set -x
set -e

. json_dd_reader.sh

IP=$1 ; shift 1
ID=$1 ; shift 1

cred_create_with_dat() {
    
    Ck=cmd
    Rk=requested-key
    Bk=byline
    Nk=nickname
    Fk=firstname
    Lk=lastname
    Ak=address
    Zk=zip
    Tk=thumbnail
    Sk=servicelevel
    Mk=ttl

    C=cred-create
    R=${ID}
    B=$1 ; shift 1
    N=$1 ; shift 1
    F=$1 ; shift 1
    L=$1 ; shift 1
    A=$1 ; shift 1
    Z=94022
    T=""
    S=0
    M=43200

    SLID=`echo '{
        "'${Ck}'":"'${C}'",
        "'${Rk}'":"'${R}'",
        "'${Bk}'":"'${B}'",
        "'${Nk}'":"'${N}'",
        "'${Fk}'":"'${F}'",
        "'${Lk}'":"'${L}'",
        "'${Ak}'":"'${A}'",
        "'${Zk}'":'${Z}',
        "'${Mk}'":'${M}',
        "'${Tk}'":"'${T}'",
        "'${Sk}'":'${S}'}' | nc ${IP} 8089`

    RET= ; json_2_cred_key ${SLID}

    ID=$RET

    echo ${RET}
        
}
cred_create() {
    
    Ck=cmd
    Rk=requested-key
    Bk=byline
    Nk=nickname
    Fk=firstname
    Lk=lastname
    Ak=address
    Zk=zip
    Tk=thumbnail
    Sk=servicelevel

    C=cred-create
    R=${ID}
    B="this is a byline, can be anything"
    N=alvin
    F=bob
    L=garrow
    A="359 State Street, Los Altos, CA 94022"
    Z=94022
    T=""
    S=0

    SLID=`echo '{
        "'${Ck}'":"'${C}'",
        "'${Rk}'":"'${R}'",
        "'${Bk}'":"'${B}'",
        "'${Nk}'":"'${N}'",
        "'${Fk}'":"'${F}'",
        "'${Lk}'":"'${L}'",
        "'${Ak}'":"'${A}'",
        "'${Zk}'":'${Z}',
        "'${Tk}'":"'${T}'",
        "'${Sk}'":'${S}'}' | nc ${IP} 8089`

    RET= ; json_2_cred_key ${SLID}

    ID=$RET

    echo ${RET}
        
}
cred_fetch() {
    echo '{"cmd":"cred-fetch","requested-key":"'${ID}'"}' | nc ${IP} 8089
}
cred_create_with_dat "$@"
cred_fetch
