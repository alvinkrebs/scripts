#!/bin/sh
## set -x

export LANG=C

. ./json_dd_reader.sh

LUKE=luke.larcnetworks.com
BASE64ARG=-D

if [ $(uname) = "Linux" ]; then
    BASE64ARG=-d
fi

create_dd() {

    if [ $# -ne 1 ]; then
        echo "usage: create_dd server"
        exit 1
    fi

    ## tokens for the local content.
    ##
    DD=$(echo '{"cmd":"create-dd"}' | nc ${1} 8089)
    if [ -z ${DD} ]; then
        echo could not create owner/writer ...
        exit 1
    fi
    RET= ; json_2_create_dd ${DD}
    O=$(dirname ${RET})
    W=$(basename ${RET})

    ## tokens for local cube to write a segment and for the foreign cube
    ## to read a segment
    ##
    DD=$(echo '{"cmd":"create-dd"}' | nc ${LUKE} 8089)
    if [ -z ${DD} ]; then
        echo could not create owner/writer ...
        exit 1
    fi
    RET= ; json_2_create_dd ${DD}
    SegO=$(dirname ${RET})
    SegW=$(basename ${RET})
    ## echo "Sky Segments: ${SegO}/${SegW}"

    ## tokens for the foreign cube to acknowledge the receipt of a token, and
    ## for the local cube to remove a segment from the sky
    ##
    DD=$(echo '{"cmd":"create-dd"}' | nc ${LUKE} 8089)
    if [ -z ${DD} ]; then
        echo could not create owner/writer ...
        exit 1
    fi
    RET= ; json_2_create_dd ${DD}
    SynFgnO=$(dirname ${RET})
    SynFgnW=$(basename ${RET})
    ## echo "Foreign Ctrl: ${SynFgnO}/${SynFgnW}"

    ## tokens for the local cube to acknowledge the receipt of a token, and
    ## for the local cube to remove a segment from the sky
    ##
    DD=$(echo '{"cmd":"create-dd"}' | nc ${LUKE} 8089)
    if [ -z ${DD} ]; then
        echo could not create owner/writer ...
        exit 1
    fi
    RET= ; json_2_create_dd ${DD}
    SynLocO=$(dirname ${RET})
    SynLocW=$(basename ${RET})
    ## echo "Local Ctrl  : ${SynLocO}/${SynLocW}"

}
stream_file() {
    if [ $# -ne 4 ]; then
        echo "usage: stream_file server ttl writer_token file"
        exit 1
    fi
    /bin/sh ./TryUpload2.q $1 $2 $3 $4
}
chunk_dd() {

    if [ $# -lt 4 ]; then
        echo "need owner_token segment_count server file"
        exit 1
    fi

    ChunkSrv=${5-"localhost"}

    ## this is the token that points to the DD containing the file you'd like to
    ## chunk and send to another cube. You have to have sent the file to the local
    ## cube to have this token full of stuff. There are checks on the server asserting
    ## several properties regarding the contained file. Writer is not used, the file
    ## should have been written by now.
    ##
    Ok=file_owner

    ## this is where the local cube will write a segment's worth of data to the sky
    ## the reader token is used by the foreign cube to pull down that segment. The
    ## reader token is shared out of band.
    ##
    Sk=segment_writer

    ## sync_reader is the reader token used by the server to wait for the client
    ## to pull content from the sky. After receiving this message, the server 
    ## continues to push another segment up to the sky.
    ##
    Rk=sync_reader

    ## sync_writer is the writer token used by the server to write back the
    ## message "go_ahead_local" after it has pushed a segment up to the sky
    ##
    Wk=sync_writer

    ## control ...
    ##
    Ck=cmd
    Tk=ttl
    Sek=segments
    Spk=slip

    ## meta ...
    ##
    Fk=filename
    Pk=payload_size
    Mk=mode

    O=${1}
    S=${SegW}
    R=${SynFgnO}
    W=${SynLocW}

    C=chunk_dd
    F=${4}
    if [ $(uname) = "Linux" ]; then
        P=$(stat -c"%s" ${4})
        M=$(stat -c"%a" ${4})
    else
        P=$(stat -L -f"%z" ${4})
        M=$(stat -f"%p" ${4} | sed -E 's/.*(.{3})/\1/')
    fi
    T=2880
    Se=$2
    Sp=10

    ## this is what you run to move the chunks ...
    ##
    echo "echo " "'"'{"segment_reader":"'${SegO}'","ctrl_writer":"'${SynFgnW}'","ctrl_reader":"'${SynLocO}'","segment_count":10}'"'" '| nc '${ChunkSrv}' 8091'

    ID=`echo '{
        "'${Ok}'":"'${O}'",
        "'${Sk}'":"'${S}'",
        "'${Rk}'":"'${R}'",
        "'${Wk}'":"'${W}'",
        "'${Ck}'":"'${C}'",
        "'${Tk}'":'${T}',
        "'${Sek}'":'${Se}',
        "'${Spk}'":'${Sp}',
        "'${Fk}'":"'${F}'",
        "'${Pk}'":'${P}',
        "'${Mk}'":'${M}'}' | nc ${3} 8089`
}

if [ $# -lt 2 ]; then
    echo "need file server"
    exit 1
fi

ChnkSrv=${3-"localhost"}

rm -rf $(pwd)/dumper

create_dd   ${2}
stream_file ${2} 1440 ${W} ${1}
chunk_dd    ${O} 10   ${2} ${1} ${ChnkSrv}

exit 0
