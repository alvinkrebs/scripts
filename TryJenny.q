#!/bin/sh

##################  Full Conversation  ###############################################################
##  1. App  -> Sky  : request to send content to Cube, wait
##  2. Sky  -> Cube : read pending messages, periodic, long delay
##  3. Sky  <- Cube : write back confirmation request
##  4. App  <- Sky  : receive confirmation request
##  5. App  -> Sky  : write back response to confirmation request, wait
##  6. Cube <- Sky  : receive confirmation response from App
##  7. Cube -> Sky  : create landing site for the foreign cube
##  8. Cube -> Sky  : write back the writer on sky to be used by the foreign cube
##  9. App  <- Sky  : receive writer token on sky for foreign cube to place content
## 10. App  -> Frgn : create landing site for the content
## 11. App  -> Frgn : write content to foreign cube
## 12. Frgn -> Sky  : by way of forward-dd, content is placed on sky after it is written locally on Frgn
## 13. Cube <- Sky  : receive content from Sky on owner token steup in step 8.
######################################################################################################

##################  Applications's Perspective  ######################################################
##  1. App  -> Sky  : request to send content to Cube, wait
##  4. App  <- Sky  : receive confirmation request
##  5. App  -> Sky  : write back response to confirmation request, wait
##  9. App  <- Sky  : receive writer token on sky for foreign cube to place content
## 10. App  -> Frgn : create landing site for the content
## 11. App  -> Frgn : write content to foreign cube
######################################################################################################

################## Home Cube's Perpective  ###########################################################
##  2. Sky  -> Cube : read pending messages, periodic, long delay
##  3. Sky  <- Cube : write back confirmation request
##  6. Cube <- Sky  : receive confirmation response from App
##  7. Cube -> Sky  : create landing site for the foreign cube
##  8. Cube -> Sky  : write back the writer on sky to be used by the foreign cube
## 13. Cube <- Sky  : receive content from Sky on owner token steup in step 8.
######################################################################################################

set -x

SKYM=96.90.247.83
CUBE=${1-192.168.200.190}
FRGN=${2-192.168.200.166}
TTL=1

## Step 0. Create a paired relationship between your home cube and Sky. I used
## create-pair to do this, runs on Cube
##
CUBE_O=
SKYM_O=
SKYM_W=
SKY_MEDIA_O=
SKY_MEDIA_W=
FRGN_W=
ID=
##
create_pair() {

    ## CREATE ...
    ##
    SECRET=`echo '{"cmd":"create-matrix-pair","left":"felix","right":"oscar","pair_name":"FelixAndOscar"}' | nc ${CUBE} 8089 |
        perl -ne ' use JSON; print decode_json($_)->{'left'}, "/", decode_json($_)->{'right'};'`

    export SKYPAIR=`basename ${SECRET}`

    ## LEFT SIDE DDs ...
    ##
    LOC=`echo '{"cmd":"retrieve-pairing-for-name","pass_phrase":"'${SKYPAIR}'"}' | nc ${CUBE} 8089 |
        perl -ne ' use JSON; print
            decode_json($_)->{'gae_writer_token'}, "/",
            decode_json($_)->{'gae_owner_token'}, "/",
            decode_json($_)->{'cube_owner_token'};'`

    CUBE_O=`basename ${LOC}` ; LOC=`dirname ${LOC}`
    SKYM_O=`basename ${LOC}` ; LOC=`dirname ${LOC}`
    SKYM_W=${LOC}

}
delete_one() {
    echo '{"cmd":"delete-entry","owner_token":"'${1}'","msgid":"'${3}'"}' | nc ${2} 8089
}
J1=""
just_one() {

    IDMSG=`echo '{"cmd":"read-entry","owner_token":"'${1}'"}' | nc ${2} 8089 | 
        perl -ne '
            use JSON;
            foreach $e ( @{ decode_json($_) } ) {
                print $e->{'data'}, "/", $e->{'msgid'}, "\n";
                exit;
            }'`
    if [ ${IDMSG}x = "x" ]; then
        echo "Nothing from $1 on $2"
        return
    fi
    ID=`basename ${IDMSG} | awk -F"." '{ print $1; }'`
    J1=`dirname ${IDMSG} | base64 -D`
    if [ ${ID}x != "x" ]; then
        if [ ${J1}x != "x" ]; then
            ## delete_one ${1} ${2} ${ID}
            return
        fi
    fi

    echo "nothing for $1 on $2 ..."

}
OW=""
owner_writer() {
    export OW=`echo '{"cmd":"create-dd"}' | nc ${1} 8089 | 
        perl -ne 'use JSON; print decode_json($_)->{'owner_token'}, "/", decode_json($_)->{'writer_token'};'`
}

## Step 1, runs on App
## App -> Sky, wait
##
## Request to send content home
##
app_request_to_send() {

    DESTINATION=$1
    FILENAME=$2
    FILESIZE=`stat ${FILENAME} | awk '{ print $8; }'`
    FILETYPE=`file -b ${FILENAME} | awk '{ print $1; }'`
    DESTMD5=`echo ${DESTINATION} | md5`
    MSG=${DESTMD5}/${FILENAME}/${FILESIZE}/${FILETYPE}/FORCUBE

    echo '{"cmd":"write-dd","ttl":'${TTL}',"writer_token":"'${SKYM_W}'","data":"'${MSG}'"}' | nc ${SKYM} 8089

}
## Steps 2 and 3, runs on Cube
## Sky -> Cube read pending messages, periodic, long delay
## Sky <- Cube, write back confirmation request
## 
## Cube reads messages from sky, Cube writes back PENDING confirmation message
##
cube_wait_to_recv() {

    just_one ${SKYM_O} ${SKYM}

    if [ ${J1}x = "x" ]; then
        echo "Nothing from ${SKYM_O} on ${SKYM}"
        exit 1
    fi

    CONFIRM="been asked to take $J1"
    FOR_WHO=`basename $J1`  ; J1=`dirname $J1`
    if [ ${FOR_WHO} != "FORCUBE" ]; then
        echo "Not for me ..."
        return
    fi
    if [ ${ID}x = "x" ]; then
        echo "No id ..."
        return
    fi
    delete_one ${SKYM_O} ${SKYM} ${ID}
    FILETYPE=`basename $J1` ; J1=`dirname $J1`
    FILESIZE=`basename $J1` ; J1=`dirname $J1`
    FILENAME=`basename $J1` ; J1=`dirname $J1`
    DESTMD5=`basename $J1`
    J1=${DESTMD5}/${FILENAME}/${FILESIZE}/${FILETYPE}/PENDING/FORAPP

    echo '{"cmd":"write-dd","ttl":'${TTL}',"writer_token":"'${SKYM_W}'","data":"'${J1}'"}' | nc ${SKYM} 8089

}
## Steps 4 and 5, runs on App
## App <- Sky, receive confirmation request
## App -> Sky, write back response to confirmation request
##
## App reads messages from sky, App writes back confirmation message
##
app_wait_to_recv() {

    just_one ${SKYM_O} ${SKYM}

    FOR_WHO=`basename $J1`  ; J1=`dirname $J1`
    if [ ${FOR_WHO} != "FORAPP" ]; then
        echo "Not for me ..."
        return
    fi
    if [ ${ID}x = "x" ]; then
        echo "No id ..."
        return
    fi
    delete_one ${SKYM_O} ${SKYM} ${ID}

    CONFIRM="been asked to confirm $J1"
    RESSPONSE=`basename $J1` ; J1=`dirname $J1`
    FILETYPE=`basename $J1` ; J1=`dirname $J1`
    FILESIZE=`basename $J1` ; J1=`dirname $J1`
    FILENAME=`basename $J1` ; J1=`dirname $J1`
    DESTMD5=`basename $J1` ; J1=`dirname $J1`
    J1=${DESTMD5}/${FILENAME}/${FILESIZE}/${FILETYPE}/YES/FORCUBE

    echo '{"cmd":"write-dd","writer_token":"'${SKYM_W}'","data":"'${J1}'"}' | nc ${SKYM} 8089

}
## Steps 6, 7,  and 8, runs on Cube
## Cube <- Sky, receive confirmation response from App
## Cube -> Sky, create landing site for the foreign cube
## Cube -> Sky, write back the writer on sky to be used by the foreign cube
##
## Cube reads messages from sky, Cube realizes that App has confirmed, Cube creates a token pair
## on Sky, Cube sends back these tokens to App
##
cube_wait_to_prepare() {

    echo "cube_wait_to_prepare, waiting ..."

    sleep 2

    ## 6
    ##
    just_one ${SKYM_O} ${SKYM}
    FOR_WHO=`basename $J1`  ; J1=`dirname $J1`
    if [ ${FOR_WHO} != "FORCUBE" ]; then
        echo "Not for me ..."
        return
    fi
    if [ ${ID}x = "x" ]; then
        echo "No id ..."
        return
    fi
    delete_one ${SKYM_O} ${SKYM} ${ID}

    CONFIRM=`basename $J1`

    if [ "YES" != ${CONFIRM} ]; then
        return
    fi

    ## 7
    ##
    owner_writer ${SKYM}

    SKY_MEDIA_TRANSFER_O=`dirname ${OW}`
    SKY_MEDIA_TRANSFER_W=`basename ${OW}`
    MSG=${SKY_MEDIA_TRANSFER_O}/${SKY_MEDIA_TRANSFER_W}/FORAPP

    ## 8
    ##
    echo '{"cmd":"write-dd","writer_token":"'${SKYM_W}'","data":"'${MSG}'"}' | nc ${SKYM} 8089

}
## Steps 9, 10, and 11, runs on App
## App <- Sky, receive writer token on sky for foreign cube to place content
## App -> Frgn, create landing site for the content
## App -> Frgn, write content to foreign cube
##
## App reads information from Sky, it now knows where on Sky to tell the foreign cube to place the 
## media, App creates a DD on the foreign Cube, App writes media and where to place the content on Sky
## to the foreign cube
##
app_to_foreign() {

    echo "app_to_foreign, waiting ..."

    sleep 2

    ## 9
    ##
    just_one ${SKYM_O} ${SKYM}
    FOR_WHO=`basename $J1`  ; J1=`dirname $J1`
    if [ ${FOR_WHO} != "FORAPP" ]; then
        echo "Not for me ..."
        return
    fi
    if [ ${ID}x = "x" ]; then
        echo "No id ..."
        return
    fi
    delete_one ${SKYM_O} ${SKYM} ${ID}
    SKY_MEDIA_O=`dirname ${J1}`
    SKY_MEDIA_W=`basename ${J1}`
    
    ## 10
    ##
    owner_writer ${FRGN}

    FRGN_W=`basename ${OW}`

    ## this is pending work ...
    ##
    ## [ ] like the invite system, we have to have symlinks to storage
    ## [ ] we have to use the md5 of the name of the collection as a destination on the final Cube
    ##
    DESTINATION=$1
    CONTENT=`cat $2`

    ## 11
    ##
    echo '{"cmd":"forward-dd","writer_token":"'${FRGN_W}'","forward_token":"'${SKY_MEDIA_W}'","data":"'${CONTENT}'"}' |
        nc ${FRGN} 8089

}
## Step 12, actually done in the prior step, but, this is to simulate the lag, or use of off-hours to 
## place content on Sky, runs on Foreign Cube
## Frgn -> Sky, by way of forward-dd, content is place on sky after it is written locally on Foreign
##
## At some convenient time, Foreign cube reads out the message from App and sends it to Sky
##
foreign_to_sky() {
    echo "hit return after pushing the content from ${FRGN} ..."
    read A
}
## Step 13, runs on Cube
## Cube <- Sky, receive content from Sky on owner token steup in step 8.
##
## Cube reads Sky DD for content and places it in the appropriate index
##
sky_to_cube() {

    echo '{"cmd":"read-entry","owner_token":"'${SKY_MEDIA_O}'"}' | nc ${SKYM} 8089 |
        perl -ne '
            use JSON;
            foreach $e ( @{ decode_json($_) } ) {
                print $e->{'data'};
                exit;
            }' | base64 -D

    ## write-dd to the corresponding hash 

    ## done

}

## MAIN

create_pair

app_request_to_send BunchOAs CC

cube_wait_to_recv

app_wait_to_recv

cube_wait_to_prepare

app_to_foreign BunchOAs CC

foreign_to_sky

sky_to_cube

exit 0
