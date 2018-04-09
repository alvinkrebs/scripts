#!/bin/sh

IP=${1-"192.168.200.169"}

ID1="9a523358d7bef5e9c5a81b9bd790bd0d2f69ea823d35d6a6a5e5f4a317bbce7f"
ID2="9da66859e7687879976e58d11f74e9c9c02f636b257bb688bfc5bad4d1ccfeb4"
ID3="760441f6a62532c5c3c2b32b6d5d20346ed069f833a6bb97166fca2b8f52509f"
ID3="3947301749ca3bcebd3baa8e98c53a4898e27e08ca75bdc2bf603216015ab3e8"

APP="com.larcnetworks.lxdrive"
APP="com.larcnetworks.xync"

MSG=$(date +"yet another message from bobg at %s unix time ...")

phrase=`echo '{"cmd":"lchat-start","ttl":6,"device_token":"'${ID1}'","device_app":"'${APP}'","type":"osx"}' | nc ${IP} 8089 |
    perl -ne 'use JSON; print decode_json($_)->{'phrase'};'`

echo $phrase
echo '{"ttl":60,"cmd":"lchat-join","device_token":"'${ID2}'","device_app":"'${APP}'","phrase": "'${phrase}'","type":"osx"}' | nc ${IP} 8089
echo '{"cmd":"lchat-join","device_token":"'${ID3}'","device_app":"'${APP}'","phrase": "'${phrase}'","type":"osx"}' | nc ${IP} 8089
echo '{"cmd":"lchat-write","device_token":"'${ID1}'","device_app":"'${APP}'","phrase": "'${phrase}'","message":"'${MSG}'"}' | nc ${IP} 8089
echo '{"cmd":"lchat-read","phrase":"'${phrase}'"}' | nc ${IP} 8089

exit 0
