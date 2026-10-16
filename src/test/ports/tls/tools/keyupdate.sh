#!/bin/sh
# keyupdate.sh dir K|k port: an openssl s_server with the ECDSA certificate of testservers.py
# (in dir) that sends a KeyUpdate (K: update requested) before a 5 byte answer; then
#   SSL_CERT_FILE=dir/ca.pem build/httpsGet localhost port /
# the -msg log shows the KeyUpdates and whether our close_notify (new keys) decrypted
d=$1
( sleep 3; printf "$2\n"; sleep 1; printf 'HTTP/1.1 200 OK\r\nContent-Length: 5\r\nConnection: close\r\n\r\nhello'; sleep 3; printf "Q\n" ) |
  timeout 30 openssl s_server -accept $3 -cert $d/c18444.pem -key $d/k18444.pem -tls1_3 -naccept 1 -msg 2>&1
