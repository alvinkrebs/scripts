#!/bin/sh

if [ $# -ne 3 ]; then
    echo "Usage: TryMatrixID matrix_name birthplace mothers_maiden_name"
    exit 1
fi

#set -x
#set -e

NAME=$1
BIRTHPLACE=$(echo $2|base64)
MAIDENNAME=$(echo $3|base64)
HOST=banana
HOST=luke.larcnetworks.com

Q1="What is the middlename of first child?"
Q2="What was the name of your first pet?"
Q3="What was the color of your first car?"
Q4="What was the name of your high school?"
Q5="What was the name of your elementary school?"

bQ1=$(echo ${Q1}|base64)
bQ2=$(echo ${Q2}|base64)
bQ3=$(echo ${Q3}|base64)
bQ4=$(echo ${Q4}|base64)
bQ5=$(echo ${Q5}|base64)

/bin/echo -n "${Q1} " && read A1
/bin/echo -n "${Q2} " && read A2
/bin/echo -n "${Q3} " && read A3
/bin/echo -n "${Q4} " && read A4
/bin/echo -n "${Q5} " && read A5

bA1=$(echo ${A1}|base64)
bA2=$(echo ${A2}|base64)
bA3=$(echo ${A3}|base64)
bA4=$(echo ${A4}|base64)
bA5=$(echo ${A5}|base64)

## how a hash is created on the server ...
## HASH=$(echo -n ${BIRTHPLACE} ${MAIDENNAME} ${bA1} ${bA2} ${bA3} ${bA4} ${bA5}|md5)

## ask if matrix_id exists, returns time left. Negative indicates that the id does
## exist, but has expired.
##
RET=$(echo '{"cmd":"matrix-id-exists","matrix_name":"'${NAME}'"}' | nc ${HOST} 8089)
echo "This is the result of your matrix-id-exists request ..."
echo "    "${RET}

## provide all the elements that need to be stored
##
## 1. the matrix_id
## 2. whether or not to renew the matrix_id after the ttl expires
## 3. the ttl, number of seconds that this matrix_id is valid
## 4. the five questions asked for security reasons
##
## returns Success if matrix_id was created
##
RET=$(echo '{
    "cmd":"create-matrix-id",
    "matrix_name":"'${NAME}'",
    "autorenew":true,
    "expiration":144000,
    "maiden_name":"'${MAIDENNAME}'",
    "birthplace":"'${BIRTHPLACE}'",
    "security_1":"'${bA1}'",
    "security_2":"'${bA2}'",
    "security_3":"'${bA3}'",
    "security_4":"'${bA4}'",
    "security_5":"'${bA5}'"}' | nc ${HOST} 8089)

echo "This is the result of your create-matrix-id request ..."
echo "    "${RET}

## return the five questions asked ...
##
RET=$(echo '{"cmd":"get-questions","matrix_name":"'${NAME}'"}' | nc ${HOST} 8089)
echo "These are the questions that were asked ..."
echo "    "${RET}

## challenge user for their matrix_id. Send ...
##
## 1. birthplace
## 2. mother's maiden name (what if they're orphans??)
## 3. the five security answers
##
## these values are hashed and compared to the stored hash value
## returns the matrix_id, or nothing if no match
RET=$(echo '{
    "cmd":"challenge-user",
    "maiden_name":"'${MAIDENNAME}'",
    "birthplace":"'${BIRTHPLACE}'",
    "security_1":"'${bA1}'",
    "security_2":"'${bA2}'",
    "security_3":"'${bA3}'",
    "security_4":"'${bA4}'",
    "security_5":"'${bA5}'"}' | nc ${HOST} 8089)

echo "This is the result of your challenge-user request ..."
echo "    "${RET}
