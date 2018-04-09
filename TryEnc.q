#!/bin/sh
set -x
set -e
F=$1
PUB=public-key.pem
PRV=private-key.pem
SBJ='/CN=www.larc.com/O=LARC/C=US'

echo Generate Key
openssl req -x509 -nodes -newkey rsa:2048 -keyout ${PRV} -out ${PUB} -subj ${SBJ}

echo Encrypt File
openssl smime -encrypt -binary -aes256 -in ${F} -out ${F}.dat -outform DER ${PUB}

echo Decrypt
openssl smime -decrypt -in ${F}.dat -binary -inform DEM -inkey ${PRV} -out ${F}.dec

echo MD5s
md5 ${F}*
