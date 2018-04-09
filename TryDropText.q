#!/bin/sh
IP=${1-192.168.200.228}
echo '{"cmd":"drop-text","skynet":true,"payload":"'`cat big`'"}' | nc ${IP} 8089
