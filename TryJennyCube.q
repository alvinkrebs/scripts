#!/bin/sh
##
## this script can run remotely, but, the idea is to run this on your home cube
## sending the paired tokens to your application and using these tokens to push
## content, by way of polling, back to this cube. You can run this on any cube
## by starting with - TryJennyCube.q localhost. This will echo back a string to
## use when starting the other script, TryJennyApp.q, run that, and add an ip
## address representing the foreign cube.
##
## set -x
##
SKYM=96.90.247.83
SKYM=64.79.159.14
CUBE=${1-localhost}
SKYM_O=${2-""}
SKYM_W=${3-""}
TTL=1
DELAY=4
POLL=30
GIVEUP=15
SKY_RETRY=2
OS=`uname`
DFLAG="-d"
PIX=`awk -F: '/PICTURE/ { print $3; }' /pi/larc/bin/host/token_file.txt`
TARGETDIR=/home/lobby/Export
STORAGE=/pi/larc/bin/host/ddstorage/storage
export PATH=${PATH}:/pi/larc/bin/host/scripts
##
## Step 0. Create a paired relationship between your home cube and Sky. I used
## create-pair to do this
##
CUBE_O=
SKY_MEDIA_O=
FILENAME=
##
lg() {
    echo -n `date` && echo "::"$*
}
create_pair() {

    ## CREATE ...
    ##
    SECRET=`echo '{"cmd":"create-matrix-pair","left":"laverne","right":"shirley","pair_name":"LaverneAndShirley"}' | nc ${CUBE} 8089 |
        perl -ne ' use JSON; print decode_json($_)->{'left'}, "/", decode_json($_)->{'right'};'`

    SKYPAIR=$(basename ${SECRET})
    echo "SECRET : ${SECRET}"
    echo "SKYPAIR: ${SKYPAIR}"

    ## LEFT SIDE DDs ...
    ##
    LOC=`echo '{"cmd":"retrieve-pairing-for-name","pass_phrase":"'${SKYPAIR}'"}' | nc ${CUBE} 8089 |
        perl -ne ' use JSON; print
            decode_json($_)->{'gae_writer_token'}, "/",
            decode_json($_)->{'gae_owner_token'}, "/",
            decode_json($_)->{'cube_owner_token'};'`

    if [ -z ${LOC} ]; then
        echo "required response from server fails ..."
        exit 1
    fi

    CUBE_O=$(basename ${LOC}) ; LOC=$(dirname ${LOC})
    SKYM_O=$(basename ${LOC}) ; LOC=$(dirname ${LOC})
    SKYM_W=${LOC}

    echo "create-pair: SKYPAIR ${SKYPAIR} is owner/writer ${SKYM_O}/${SKYM_W}"

}
delete_one() {
    echo '{"cmd":"delete-entry","owner_token":"'${1}'","msgid":"'${3}'"}' | nc ${2} 8089
}
J1=""
ID=""
just_one() {

    IDMSG=`echo '{"cmd":"read-entry","owner_token":"'${1}'"}' | nc ${2} 8089 |
        perl -ne '
            use JSON;
            foreach $e ( @{ decode_json($_) } ) {
                print $e->{'data'}, "/", $e->{'msgid'}, "\n";
                exit;
            }'`
    ID=""
    J1=""
    if [ -z ${IDMSG} ]; then
        return
    fi
    ID=$(basename ${IDMSG} | awk -F"." '{ print $1; }')
    J1=$(dirname ${IDMSG} | base64 ${DFLAG})

}
OW=""
owner_writer() {
    export OW=`echo '{"cmd":"create-dd"}' | nc ${1} 8089 |
        perl -ne 'use JSON; print decode_json($_)->{'owner_token'}, "/", decode_json($_)->{'writer_token'};'`
}
## Steps 2 and 3, runs on Cube
## Sky -> Cube read pending messages, periodic, long delay
## Sky <- Cube, write back confirmation request
## TTL: short
##
## Cube reads messages from sky, Cube writes back PENDING confirmation message
##
cube_wait_to_recv() {
    while [ 1 = 1 ]; do
        just_one ${SKYM_O} ${SKYM}
        if [ ! -z ${J1} ]; then
            FOR_WHO=$(basename $J1) ; J1=$(dirname $J1)
            if [ ${FOR_WHO} = "FORCUBE" ]; then
                if [ ! -z ${ID} ]; then
                    delete_one ${SKYM_O} ${SKYM} ${ID}
                    break
                fi
            fi
        fi
        sleep ${POLL}
    done

    lg "SKY->CUB[ 2]:${SKYM_O}@${SKYM} -- ${J1}"
    CONFIRM="been asked to take $J1"
    FILETYPE=$(basename $J1) ; J1=$(dirname $J1)
    FILESIZE=$(basename $J1) ; J1=$(dirname $J1)
    FILENAME=$(basename $J1) ; J1=$(dirname $J1)
    DESTMD5=$(basename $J1)  ; J1=$(dirname $J1)
    J1=${DESTMD5}/${FILENAME}/${FILESIZE}/${FILETYPE}/PENDING/FORAPP
    lg "SKY<-CUB[ 3]:${SKYM_W}@${SKYM} -- ${J1}"

    sky_write=`echo '{"cmd":"write-dd","ttl":'${TTL}',"writer_token":"'${SKYM_W}'","data":"'${J1}'"}' | nc ${SKYM} 8089`

}
## Steps 6, 7,  and 8, runs on Cube
## Cube <- Sky, receive confirmation response from App
## Cube -> Sky, create landing site for the foreign cube
## Cube -> Sky, write back the writer on sky to be used by the foreign cube
##
## Cube reads messages from sky, Cube realizes that App has confirmed, Cube creates a token pair
## on Sky, Cube sends back these tokens to App
## TTL: short
##
cube_wait_to_prepare() {

    ## 6
    ##
    giveup=${GIVEUP}
    while [ 1 = 1 ]; do
        just_one ${SKYM_O} ${SKYM}
        if [ ! -z ${J1} ]; then
            FOR_WHO=$(basename $J1) ; J1=$(dirname $J1)
            if [ ${FOR_WHO} = "FORCUBE" ]; then
                if [ ! -z ${ID} ]; then
                    delete_one ${SKYM_O} ${SKYM} ${ID}
                    break
                fi
            fi
        fi
        giveup=$(expr ${giveup} - 1)
        if [ ${giveup} -eq 0 ]; then
            return
        fi
        sleep ${DELAY}
    done

    CONFIRM=$(basename $J1)

    if [ "YES" != ${CONFIRM} ]; then
        return
    fi

    lg "SKY->CUB[ 6]:${SKYM_O}@${SKYM} -- ${J1}"
    ## 7
    ##
    owner_writer ${SKYM}
    lg "SKY<-CUB[ 7]:requesting tokens on Sky for remote cube upload."

    SKY_MEDIA_TRANSFER_W=$(basename ${OW})
    SKY_MEDIA_O=$(dirname ${OW})
    MSG=${SKY_MEDIA_TRANSFER_W}/FORAPP
    lg "SKY<-CUB[ 8]:${SKYM_W}@${SKYM} -- ${MSG} SMO=${SKY_MEDIA_O}"

    ## 8
    ##
    sky_write=`echo '{"cmd":"write-dd","writer_token":"'${SKYM_W}'","ttl":'${TTL}',"data":"'${MSG}'"}' | nc ${SKYM} 8089`

}
sky_to_cube_large() {

    giveup=5
    delay=240
    target=${TARGETDIR}/${FILENAME-ID}

    if [ -f ${target} ]; then
        rm ${target}
    fi

    start=$(date +%s)
    while [ 1 = 1 ]; do
        sleep ${delay}
        lg TryStreamDL.q ${SKY_MEDIA_O} ${target}
        TryStreamDL.q ${SKY_MEDIA_O} ${target}
        DLSIZE=$(stat --format=%s ${target})

        if [ -z ${DLSIZE} ]; then
            continue
        fi

        if [ ${FILESIZE} -eq ${DLSIZE} ]; then
            break
        fi

        giveup=$(expr ${giveup} - 1)
        if [ ${giveup} -eq 0 ]; then
            lg "Giving up ..."
            return
        fi
    done
    stop=$(date +%s)
    elapsed=$(expr ${stop} - ${start})

    exp=$(expr ${stop} + 3600)
    uuid=$(cat /proc/sys/kernel/random/uuid).${exp}
    cp ${target} ${STORAGE}/${PIX}/${uuid}

    SKY_RETRY=2
    FILENAME=""
    lg "SKY->CUB[13]:${SKY_MEDIA_O}@${SKYM} -- large content from sky in ${elapsed} seconds, cp to ${PIX}/${uuid}"

}
## Step 13, runs on Cube
## Cube <- Sky, receive content from Sky on owner token setup in step 8.
##
## Cube reads Sky DD for content and places it in the appropriate index
## TTL: long
##
sky_to_cube() {

    if [ ${FILESIZE} -gt 1000000 ]; then
        sky_to_cube_large
        return
    fi

    ## we need to give the download enough time to complete, not sure how long that is
    ##
    giveup=120
    while [ 1 = 1 ]; do
        sleep ${DELAY}
        ID=`echo '{"cmd":"read-entry","owner_token":"'${SKY_MEDIA_O}'"}' | nc ${SKYM} 8089 |
            perl -ne '
                use JSON;
                foreach $e ( @{ decode_json($_) } ) {
                    print $e->{'msgid'}, "\n";
                    exit;
                }'`

        if [ ! -z ${ID} ]; then
            delete_one ${SKY_MEDIA_O} ${SKYM} ${ID}
            break
        fi
        giveup=$(expr ${giveup} - 1)
        if [ ${giveup} -eq 0 ]; then
            lg "Giving up ..."
            return
        fi
    done

    start=$(date +%s)
    target=${TARGETDIR}/${FILENAME-ID}
    if [ ${target##.*} != "mp4" ]; then
        target=${target}.mp4
    fi

    if [ -f ${target} ]; then
        rm ${target}
    fi

    echo '{"cmd":"read-entry","owner_token":"'${SKY_MEDIA_O}'"}' | nc ${SKYM} 8089 |
        perl -ne '
            use JSON;
            foreach $e ( @{ decode_json($_) } ) {
                print $e->{'data'};
                exit;
            }' | base64 ${DFLAG} > ${target}
    stop=$(date +%s)

    elapsed=$(expr ${stop} - ${start})
    DLSIZE=$(stat --format=%s ${target})

    if [ ${FILESIZE} -ne ${DLSIZE} ]; then
        lg "SKY->CUB[13]:${SKY_MEDIA_O}@${SKYM} -- FAIL!! short file. expected ${FILESIZE} but got ${DLSIZE} in ${elapsed} seconds"
        rm ${target}
        if [ 0 -ne ${SKY_RETRY} ]; then
            SKY_RETRY=$(expr ${SKY_RETRY} - 1)
            lg " ... retrying"
            sky_to_cube
        else
            SKY_RETRY=2
            FILENAME=""
            lg " ... giving up"
            delete_one ${SKY_MEDIA_O} ${SKYM} ${ID}
        fi
    else
        exp=$(expr ${stop} + 3600)
        uuid=$(cat /proc/sys/kernel/random/uuid).${exp}
        cp ${target} ${STORAGE}/${PIX}/${uuid}
        lg "SKY->CUB[13]:${SKY_MEDIA_O}@${SKYM} -- content from sky in ${elapsed} seconds, cp to ${PIX}/${uuid}"
        SKY_RETRY=2
        FILENAME=""
        delete_one ${SKY_MEDIA_O} ${SKYM} ${ID}
    fi

    ## write-dd to the corresponding hash

}
sanity() {

    if [ ${OS} = "Darwin" ]; then
        DFLAG="-D"
    fi
    if [ ! -f TryStreamDL.q ]; then
        lg "Required script TryStreamDL.q not found ..."
        exit 1
    fi

    if [ ! -d ${TARGETDIR} ]; then
        mkdir -p ${TARGETDIR}
        if [ 0 -ne $? ]; then
            lg "Could not create target directory ${TARGETDIR}"
            exit 1
        fi
    fi

    ping -c 1 -t 20 ${SKYM} 2>&1  > /dev/null
    if [ 0 != $? ]; then
        lg "could not access skywalker ${SKYM}"
        exit 1
    fi

    if [ -z ${SKYM_O} ]; then
        create_pair
    fi

}

## MAIN

sanity

lg $0 " " $*

echo "sh ./TryJennyApp.q ${SKYM_O} ${SKYM_W}"

while [ 1 = 1 ]; do
    cube_wait_to_recv
    cube_wait_to_prepare
    sky_to_cube_large
    sleep ${DELAY}
done

exit 0

## samba on the cube
## apt install samba
## useradd -m lobby
## passwd lobby << l088y
## smbpasswd -a lobby << l088y
## cat<<eof>>/etc/samba/smb.conf
## [lobby]
## path = /home/lobby/Export
## valid users = lobby
## read only = no
## eof
## mount_smbfs //lobby:l088y@192.168.1.73/lobby /Users/bob/mnt 
