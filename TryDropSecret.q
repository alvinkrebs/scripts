#!/bin/sh

. ./json_dd_reader.sh

IP=${1-96.90.247.83}
HAY=${2-1}

echo "Server: $IP"

## set -x

check_hay() {

    PHR=`echo '{"cmd":"drop-secret","message":"Hello, I am a top, er, drop secret message","ttl":5,"noemoji":true,"index":["drop","secret","shh"]}' | nc ${IP} 8089 |
        perl -ne 'use JSON; print decode_json($_)->{'phrase'};'`

    /bin/echo -n "[$PHR] --> ["

    echo '{"cmd":"drop-secret","phrase":"'$PHR'","ttl":5,"index":["drop","secret","shh"]}' | nc ${IP} 8089 && echo "]"
    ##
    ## check if a haystack enabled server is actually shredding messages.
    ##
    if [ 1 = $HAY ]; then
        /bin/echo -n "second read, should be gibberish [$PHR] --> ["
        echo '{"cmd":"drop-secret","phrase":"'$PHR'","ttl":5}' | nc ${IP} 8089 && echo "]"
    fi

}
check_multi() {

    ## pull blob of concatenated b64 strings ..
    ##
    B64=$(echo '{"cmd":"drop-secret","all":true,"phrase":"Todays Lucky Winners"}' | nc ${IP} 8089)

    ## decode all b64 strings and place each in an array
    ##
    declare -a ARR=$(echo $B64 | perl -ne 'use JSON; use MIME::Base64;
        $idx = 0;
        foreach $r ( @{decode_json($_)} ) {
            printf("%s\n", $r);
        }')

    ## Application dependent, break out the resulting json and print legibly
    ##
    for i in ${ARR} ; do
        echo $i | base64 -D | perl -ne 'use JSON;
            printf("Winner %s at %s wins a %s from %s\n",
                decode_json($_)->{'Winner'}->{'Key'},
                decode_json($_)->{'Winner'}->{'Owner'},
                decode_json($_)->{'Prize'}->{'Prize'},
                decode_json($_)->{'Prize'}->{'Vendor'});'
    done

}

check_multi
