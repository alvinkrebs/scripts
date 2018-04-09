#!/bin/sh
set -x
## demonstration of collection usage, public and private
##
## create a bunch of dds, and push content to these dds
## create a collection and bind these dds inside that collection
## create another collection and bind these to a public search string
##
SERVER=luke.larcnetworks.com
COUNT=12

## create a bunch of dds ...
##
declare -a DDS=$(echo '{"cmd":"create-dd","count":'${COUNT}'}' | nc ${SERVER} 8089 | perl -ne '
    use JSON;
    foreach $dd ( @{decode_json($_)} ) {
        printf("%s/%s\n", $dd->{'owner_token'}, $dd->{'writer_token'});
    }' 2>/dev/null)

if [ 0 -eq ${#DDS[@]} ]; then
    echo "Failed to create DDs"
    exit 1
fi

## create a collection ...
##
COLLECTION=$(echo '{"cmd":"collection"}' | nc ${SERVER} 8089 | perl -ne '
    use JSON;
    print decode_json($_)->{'collection'};')

readers=
writers=
for DD in ${DDS} ; do
    OW=$(dirname ${DD})
    WR=$(basename ${DD})
    if [ -z ${readers} ]; then
        readers="[\"${OW}\""
        writers="[\"${WR}\""
    else
        readers=${readers}",\"${OW}\""
        writers=${writers}",\"${WR}\""
    fi
done
readers=${readers}"]"
writers=${writers}"]"

## put dds in your collection
##
echo '{"cmd":"put-collection","collection":"'${COLLECTION}'","readers":'${readers}',"writers":'${writers}'}' | nc ${SERVER} 8089

## pull dds of your collection
##
echo '{"cmd":"pull-collection","collection":"'${COLLECTION}'"}' | nc ${SERVER} 8089

## create another collection ...
##
COLLECTION=$(echo '{"cmd":"collection"}' | nc ${SERVER} 8089 | perl -ne '
    use JSON;
    print decode_json($_)->{'collection'};')

## put dds in your collection, but add a public search string
##
echo '{"cmd":"put-collection","public":"aPublicSearchString","collection":"'${COLLECTION}'","readers":'${readers}',"writers":'${writers}'}' | nc ${SERVER} 8089

## pull dds of your collection back by search string
##
echo '{"cmd":"pull-collection","public":"aPublicSearchString"}' | nc ${SERVER} 8089
