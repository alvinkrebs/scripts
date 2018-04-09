#!/bin/sh

## set -x
export TZ=UTC
SKYM=64.79.159.14
DELAY=4
SHORT_TTL=2
##
## set by your home cube, who is now waiting on the owner for content from sky
## you'll need to " cpan JSON.pm" if you don't have the perl JSON interpreter
## apt install netcat-traditional
##
SKYM_O=
SKYM_W=
FILE=$2
##
## use mDns to find "_matrix" services, and use the ip address
##
FRGN=${3-192.168.200.166}
SKY_MEDIA_W=
FRGN_W=
SKY_PHRASE=$1
##
lg() {
    /bin/echo -n `date` && echo "::"$*
}
delete_one() {
    echo '{"cmd":"delete-entry","owner_token":"'${1}'","msgid":"'${3}'"}' | nc ${2} 8089
}
J1=""
just_one() {
    ID=""
    J1=""
    IDMSG=`echo '{"cmd":"read-entry","owner_token":"'${1}'"}' | nc ${2} 8089 |
        perl -ne '
            use JSON;
            foreach $e ( @{ decode_json($_) } ) {
                print $e->{'data'}, "/", $e->{'msgid'}, "\n";
                exit;
            }'`
    if [ -z ${IDMSG} ]; then
        return
    fi
    ID=$(basename ${IDMSG} | awk -F"." '{ print $1; }')
    J1=$(dirname ${IDMSG} | base64 -D)
}
OW=""
owner_writer() {
    OW=`echo '{"cmd":"create-dd"}' | nc ${1} 8089 |
        perl -ne 'use JSON; print decode_json($_)->{'owner_token'}, "/", decode_json($_)->{'writer_token'};'`
}
tokens_from_phrase() {
    if [ -z ${1} ]; then
        return
    fi
    SKY_PHRASE=`echo '{"cmd":"retrieve-pairing-for-name","pass_phrase":"'${1}'"}' | nc ${SKYM} 8089 |
        perl -ne 'use JSON; print decode_json($_)->{'gae_owner_token'}, "/", decode_json($_)->{'gae_writer_token'};'`
    if [ ! -z ${SKY_PHRASE} ]; then
        if [ "/" != ${SKY_PHRASE} ]; then
            SKYM_O=$(dirname ${SKY_PHRASE})
            SKYM_W=$(basename ${SKY_PHRASE})
        else
            SKY_PHRASE=""
        fi
    else
        echo "No sky phrase received .."
        exit 1
    fi
}
## Step 1, runs on App
## App -> Sky, wait
##
## Request to send content home
## TTL: short
##
app_request_to_send() {

    DESTINATION=$1
    FILENAME=$2
    FILESIZE=$(stat ${FILENAME} | awk '{ print $8; }')
    FILETYPE=$(file -b ${FILENAME} | awk '{ print $1; }')
    case ${FILETYPE} in
        ISO)
            FILETYPE=QuickTime
            ;;
        Audio)
            FILETYPE=mp3
            ;;
    esac
    DESTMD5=$(echo ${DESTINATION} | md5)
    MSG=${DESTMD5}/${FILENAME}/${FILESIZE}/${FILETYPE}/FORCUBE

    lg "APP->SKY[ 1]:${SKYM_W}@${SKYM} -- ${MSG}"
    sky_write=`echo '{"cmd":"write-dd","ttl":'${SHORT_TTL}',"writer_token":"'${SKYM_W}'","data":"'${MSG}'"}' | nc ${SKYM} 8089`

}
## Steps 4 and 5, runs on App
## App <- Sky, receive confirmation request
## App -> Sky, write back response to confirmation request
##
## App reads messages from sky, App writes back confirmation message
## TTL: short
##
app_wait_to_recv() {

    while [ 1 = 1 ]; do
        just_one ${SKYM_O} ${SKYM}
        if [ ! -z ${J1} ]; then
            FOR_WHO=$(basename $J1) ; J1=$(dirname $J1)
            if [ ${FOR_WHO} = "FORAPP" ]; then
                if [ ! -z ${ID} ]; then
                    delete_one ${SKYM_O} ${SKYM} ${ID}
                    break
                fi
            fi
        fi
        sleep ${DELAY}
    done
    lg "APP<-SKY[ 4]:${SKYM_O}@${SKYM} -- ${J1}"
    CONFIRM="been asked to confirm $J1"
    FILETYPE=$(basename $J1) ; J1=$(dirname $J1)
    FILESIZE=$(basename $J1) ; J1=$(dirname $J1)
    FILENAME=$(basename $J1) ; J1=$(dirname $J1)
    DESTMD5=$(basename $J1) ; J1=$(dirname $J1)
    J1=${DESTMD5}/${FILENAME}/${FILESIZE}/${FILETYPE}/YES/FORCUBE

    lg "APP->SKY[ 5]:${SKYM_W}@${SKYM} -- ${J1}"
    sky_write=`echo '{"cmd":"write-dd","ttl":'${SHORT_TTL}',"writer_token":"'${SKYM_W}'","data":"'${J1}'"}' | nc ${SKYM} 8089`

}
## Steps 9, 10, and 11, runs on App
## App <- Sky, receive writer token on sky for foreign cube to place content
## App -> Frgn, create landing site for the content
## App -> Frgn, write content to foreign cube
##
## App reads information from Sky, it now knows where on Sky to tell the foreign cube to place the
## media, App creates a DD on the foreign Cube, App writes media and where to place the content on Sky
## to the foreign cube
## TTL: short(9) then long
##
app_to_foreign() {

    ## 9
    ##
    while [ 1 = 1 ]; do
        just_one ${SKYM_O} ${SKYM}
        if [ ! -z ${J1} ]; then
            FOR_WHO=$(basename $J1) ; J1=$(dirname $J1)
            if [ ${FOR_WHO} = "FORAPP" ]; then
                if [ ! -z ${ID} ]; then
                    delete_one ${SKYM_O} ${SKYM} ${ID}
                    break
                fi
            fi
        fi
        sleep ${DELAY}
    done

    SKY_MEDIA_W=$(basename ${J1})
    lg "APP<-SKY[ 9]:${SKYM_O}@${SKYM} -- ${J1}"

    ## 10
    ##
    owner_writer ${FRGN}

    FRGN_W=$(basename ${OW})
    lg "APP<-FGN[10]:create-dd@${FRGN} -- ${OW}"

    ## XXX need this stuff ...
    ##
    ## [ ] like the invite system, we have to have symlinks to storage
    ## [ ] we have to use the md5 of the name of the collection as a destination on the final Cube
    ## [ ] beef up the writer so we can send large files. This could mean transferring the content to
    ##     yet another dd, and then, asking SKY to read from that location.
    ##

    ## 11
    ##
    ## Use the SKY_MEDIA_W token to write content using the multipart/form-data support, then, send a
    ## forward-dd with an empty data element, which can mean, read from the forward_token, be sure to
    ## send the FRGN_O token to do that, and pipe that to the SKY_MEDIA_WRITER.
    ##
    FRGN_O=$(dirname ${OW})
    lg "APP->FGN[11]:TryUpload.q $2 --> ${FRGN_W} via ${FRGN}"
    sh ./TryUpload.q ${FRGN_W} ${FRGN} ${2}
    lg "FGN->SKY[12]:${FRGN_W}@${FRGN} -- forward ${2} to ${SKY_MEDIA_W} via ${FRGN_O}"
    echo '{"cmd":"forward-dd","writer_token":"'${FRGN_O}'","forward_token":"'${SKY_MEDIA_W}'","data":""}' | nc ${FRGN} 8089

}

sanity() {

    if [[ "${FILE}" =~ "/" ]]; then
        lg "sorry no slashes allowed in filename ..."
        exit 1
    fi

    if [[ "${FILE}" =~ " " ]]; then
        lg "sorry no spaces allowed in filename ..."
        exit 1
    fi

    if [ ! -f ${FILE} ]; then
        lg "could not access file ${FILE}"
        exit 1
    fi

    ping -c 1 -t 2 ${SKYM} 2>&1  > /dev/null
    if [ 0 != $? ]; then
        lg "could not access skywalker ${SKYM}"
        exit 1
    fi

    ping -c 1 -t 2 ${FRGN} 2>&1  > /dev/null
    if [ 0 != $? ]; then
        lg "could not access local cube ${FRGN}"
        exit 1
    fi

}

## MAIN

if [ $# -ge 2 ]; then
    tokens_from_phrase $1
else
cat<<eof

Usage $0 skyPhrase File [Foreign Cube]

    This is run from an endpoint, not a cube. You need to have a cube that has paired to the
    hosted service. You also need to know the ip address of the Foreign Cube you'll be sending
    your content thru.

eof
    exit 1

fi

sanity
app_request_to_send BunchOAs ${FILE}
app_wait_to_recv
app_to_foreign BunchOAs ${FILE}

exit 0
