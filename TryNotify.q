#!/bin/sh

EC=/bin/echo
IP=192.168.200.228
IP=192.168.200.229
IP=192.168.1.115
IP=${1-192.168.200.166}
## dont pair with this, wont work IP=96.90.247.83
## set -x

CreateDD() {

    OW=`echo '{"cmd":"create-dd"}' | nc ${IP} 8089 |
        perl -ne 'use JSON; print decode_json($_)->{'owner_token'}, "/", decode_json($_)->{'writer_token'};'`

    export O=`dirname ${OW}`
    export W=`basename ${OW}`

}

WriteEntries() {

    CreateDD
    W1=$W
    O1=$O

    CreateDD
    W2=$W
    O2=$O

    echo '{"cmd":"write-dds","messages":[{"cmd":"write-dd","writer_token":"'${W1}'","data":"Writing 1 '${O1}'/'${W1}'","ttl":60},{"cmd":"write-dd","writer_token":"'${W2}'","data":"Writing 2 '${O2}'/'${W2}'","ttl":60}]}' | nc ${IP} 8089
    echo '{"cmd":"read-entries","owner_token":["'${O1}'","'${O2}'"]}' | nc ${IP} 8089
    echo '{"cmd":"read-entry","owner_token":"'${O1}'"}' | nc ${IP} 8089
    echo ""
    ${EC} -n "Delete entries ... "
    read A
    echo '{"cmd":"delete-entries","owner_token":["'${O1}'","'${O2}'"]}' | nc ${IP} 8089

}

Pair() {


    ## CREATE ...
    ##
    LR=`echo '{"cmd":"create-matrix-pair","left":"leftyloosey","right":"rightytighty","pair_name":"FirstPairName"}' | nc ${IP} 8089 |
        perl -ne 'use JSON; print decode_json($_)->{'left'}, "/", decode_json($_)->{'right'};'`

    export L=`dirname ${LR}`
    export R=`basename ${LR}`

    ## LEFT SIDE DDs ...
    ##
    LOC=`echo '{"cmd":"retrieve-pairing-for-name","pass_phrase":"'${L}'"}' | nc ${IP} 8089 |
        perl -ne 'use JSON; print decode_json($_)->{'cube_owner_token'}, "/", decode_json($_)->{'cube_writer_token'};'`
    export LLO=`dirname ${LOC}`
    export LLW=`basename ${LOC}`

    GAE=`echo '{"cmd":"retrieve-pairing-for-name","pass_phrase":"'${L}'"}' | nc ${IP} 8089 |
        perl -ne 'use JSON; print decode_json($_)->{'gae_owner_token'}, "/", decode_json($_)->{'gae_writer_token'};'`
    export LGO=`dirname ${GAE}`
    export LGW=`basename ${GAE}`

    ## RIGHT SIDE DDs ...
    ##
    LOC=`echo '{"cmd":"retrieve-pairing-for-name","pass_phrase":"'${R}'"}' | nc ${IP} 8089 |
        perl -ne 'use JSON; print decode_json($_)->{'cube_owner_token'}, "/", decode_json($_)->{'cube_writer_token'};'`
    export RLO=`dirname ${LOC}`
    export RLW=`basename ${LOC}`

    GAE=`echo '{"cmd":"retrieve-pairing-for-name","pass_phrase":"'${R}'"}' | nc ${IP} 8089 |
        perl -ne 'use JSON; print decode_json($_)->{'gae_owner_token'}, "/", decode_json($_)->{'gae_writer_token'};'`
    export RGO=`dirname ${GAE}`
    export RGW=`basename ${GAE}`

    ## SHOW ...
    ##
    echo "LEFT:       handle: ${L}"
    echo "       local owner: ${LLO}, local writer ${LLW}"
    echo "         gae owner: ${LGO},   gae writer ${LGW}"

    echo "RIGHT       handle: ${R}"
    echo "       local owner: ${RLO}, local writer ${RLW}"
    echo "         gae owner: ${RGO},   gae writer ${RGW}"

}

echo Server: ${IP}

WriteEntries

Pair

exit 0
