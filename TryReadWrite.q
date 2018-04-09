#!/bin/sh
##
## set -x
## 96.90.247.82: {"owner_token":"913d503d-6b0e-48ea-49f6-13d7f8a0359f","writer_token":"f3477060-8fd2-4aba-5a3a-8ed7d9833b30"}
## 96.90.247.83: {"owner_token":"f8315a85-a541-4acc-6898-ae44c821e553","writer_token":"9e1cfe57-e749-4e7a-54b8-f424eada56d8"}
## 192.168.1.73: {"owner_token":"dfa7bac3-891e-441d-7de4-a160218eb6dc","writer_token":"31c961ef-1494-42c4-774e-09a94db3420e"}

port=8089
ttl=5

message="$(date) :: hello barracuda firewall and load balancer I am $(hostname) pleased to meet you."
data=$(echo ${message} | base64)

home() {
    ## sanity ...
    owner_token=dfa7bac3-891e-441d-7de4-a160218eb6dc
    writer_token=31c961ef-1494-42c4-774e-09a94db3420e
    server=192.168.1.73
}
the83() {
    ## sanity ...
    owner_token=f8315a85-a541-4acc-6898-ae44c821e553
    writer_token=9e1cfe57-e749-4e7a-54b8-f424eada56d8
    server=96.90.247.83
}
the82() {
    server=96.90.247.82
    owner_token=913d503d-6b0e-48ea-49f6-13d7f8a0359f
    writer_token=f3477060-8fd2-4aba-5a3a-8ed7d9833b30
}
apricot() {
    server=96.90.247.82
    owner_token=efb45c75-d9dd-4a85-5157-9ccbdabf6604
    writer_token=a989c229-4053-4363-7894-1fbed508d761
}
plum() {
    server=96.90.247.82
    owner_token=c9d8a096-197e-44eb-6b6f-4c950a2bcb11
    writer_token=c44837e8-cdda-4aa6-62df-6f1f0927529e
}

decmp=-d

echo ${data} | base64 ${decmp}
cnt=1
while [ 1 = 1 ]; do
    fruit=$(expr ${cnt} % 2)
    if [ ${fruit} -eq 0 ]; then
        plum
    else
        apricot
    fi
    cnt=$(expr ${cnt} + 1)
    date
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
    message_back=$(echo '{"cmd":"read-entry","owner_token":"'${owner_token}'"}' | nc ${server} 8089)
    if [ -z ${message_back} ]; then
        if [ $? -ne 0 ]; then
            echo read status $?
        fi
    else
        echo returns: ${message_back}
    fi
    message="$(date) :: hello barracuda firewall and load balancer I am $(hostname) pleased to meet you."
    data=$(echo ${message} | base64)
    sleep 1
done
