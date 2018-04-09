#!/bin/sh

SLEEP=30
IP=${1-192.168.200.229}

if [ -f .reader ]; then
    READER_TOKEN=`cat .reader`
else
    exit 1
fi

Decode() {

    echo '{"cmd":"read-entry","owner_token":"'${1}'"}' | nc ${IP} 8089 > Inbound

    if [ ! -s Inbound ]; then
        return
    fi

perl<<'__HERE__'
    use JSON;
    open($d, '>', "delete_me") or die "nope";
    foreach $e (@{decode_json(`cat Inbound`)}) {
        open($f, '>', $e->{msgid}.".pdf") or die "nope";
        say $f $e->{data};
        say $d $e->{msgid}."\n";
        close $f;
    }
    close $d;
__HERE__

    for i in `cat delete_me`
    do
        echo '{"cmd":"delete-entry","owner_token":"'${1}'","msgid":"'$i'"}' | nc ${IP} 8089 > Inbound
    done

    rm delete_me

}
echo "Server: $IP"
while [ 1 == 1 ]; do
    Decode ${READER_TOKEN}
    sleep ${SLEEP}
done
