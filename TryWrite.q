#!/bin/sh
##
## set -x
## vegas: {"owner_token":"3323e069-cb49-4dad-441e-02cfc175d0d8","writer_token":"892641d7-b299-41ed-48f5-9299cd50dc6d"}
## 1.73 : {"owner_token":"d9ddfa05-5250-4522-53f0-2348609bea40","writer_token":"84ca9570-1ac5-4f27-50eb-4db8d91a2c2a"}
## colo : {"owner_token":"2304ef09-cda4-4562-66fc-92b58da2b769","writer_token":"f78bfb39-3c5b-4d7b-7b8d-33c61143433e"}



server=96.90.247.83
server=luke.larcnetworks.com
server=192.168.1.73
port=8089
ttl=60

owner_token=d9ddfa05-5250-4522-53f0-2348609bea40
writer_token=84ca9570-1ac5-4f27-50eb-4db8d91a2c2a
owner_token=2304ef09-cda4-4562-66fc-92b58da2b769
writer_token=f78bfb39-3c5b-4d7b-7b8d-33c61143433e
owner_token=913d503d-6b0e-48ea-49f6-13d7f8a0359f
writer_token=f3477060-8fd2-4aba-5a3a-8ed7d9833b30
owner_token=3323e069-cb49-4dad-441e-02cfc175d0d8
writer_token=892641d7-b299-41ed-48f5-9299cd50dc6d

echo ${data} | base64 -D

while [ 1 == 1 ]; do
    date
    message="$(date) :: hello barracuda firewall and load balancer I am $(hostname) pleased to meet you."
    data=$(echo ${message} | base64)
    msgid=$(echo '{"cmd":"write-dd","ttl":'${ttl}',"writer_token":"'${writer_token}'","data":"'${data}'"}' | nc ${server} 8089)
    stat=$?
    if [ -z ${msgid} ]; then
        if [ ${stat} -ne 0 ]; then
            echo write status ${stat}
        fi
    else
        echo got one ${msgid} ... 
        if [ ${stat} -ne 0 ]; then
            echo write status ${stat}
        fi
    fi
    exit
    echo '{"cmd":"read-entry","owner_token":"'${owner_token}'"}' | nc ${server} 8089
    if [ $? -ne 0 ]; then
        echo read status $?
    fi
done
