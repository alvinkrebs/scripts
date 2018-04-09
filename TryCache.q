#!/bin/sh

. ./json_dd_reader.sh

Key=${1-"GonnaExpire"}
Cat=${2-"ORG"}
Host=${3-"luke.larcnetworks.com"}

put_cache() {

    ## get token pair
    ##
    DD=$(echo '{"cmd":"create-dd"}' | nc ${Host} 8089)
    RET= ; json_2_create_dd ${DD}
    O=$(dirname ${RET})
    W=$(basename ${RET})

    ## put cache ...
    ##
    ## lcnada_owner  := "2f35ae22-6f47-4f40-70b0-44569adf657c"
    ## lcnada_writer := "f9cd7038-0643-4c95-703d-26057a224753"
    ## echo '{"cmd":"put_cache","key":"LCNADA","category":"JUV","owner":"'${O}'","writer":"'${W}'","ttl":518400}' | nc luke.larcnetworks.com 8089
    ##
    echo '{"cmd":"put_cache","key":"'${Key}'","category":"'${Cat}'","owner":"'${O}'","writer":"'${W}'","ttl":5}' | nc ${Host} 8089

}

get_cache() {

    echo '{"cmd":"get_cache","key":"'${Key}'","category":"'${Cat}'"}' | nc ${Host} 8089

}

put_cache
##
## mongo won't commit that fast, so, when you immediately pull back the cache, it's not there
## gotta be a way to commit the write before returning.
##
sleep 10

get_cache
