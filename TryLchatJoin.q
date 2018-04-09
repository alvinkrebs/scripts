#!/bin/sh

phrase=${1-"Tango Emma Echo"}
IP=${2-"192.168.200.228"}
ID=760441f6a62532c5c3c2b32b6d5d20346ed069f833a6bb97166fca2b8f52509f
ID=9da66859e7687879976e58d11f74e9c9c02f636b257bb688bfc5bad4d1ccfeb4
ID=9a523358d7bef5e9c5a81b9bd790bd0d2f69ea823d35d6a6a5e5f4a317bbce7f
APP="com.larcnetworks.xync"
APP="com.larcnetworks.lxdrive"
MSG=$(date +"yet another message from bobg at %s unix time ...")
echo '{"cmd":"lchat-join","device_token":"'${ID}'","device_app":"'${APP}'","phrase":"'${phrase}'","type":"osx"}' | nc ${IP} 8089
echo '{"cmd":"lchat-write","device_token":"'${ID}'","device_app":"'${APP}'","phrase":"'${phrase}'","message":"'${MSG}'"}' | nc ${IP} 8089 
echo '{"cmd":"lchat-read","phrase":"'${phrase}'"}' | nc ${IP} 8089

exit 0
