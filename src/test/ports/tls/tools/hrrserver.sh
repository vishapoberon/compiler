#!/bin/sh
# hrrserver.sh dir port [p256|cookie]: an openssl s_server with the ECDSA certificate of
# testservers.py (in dir) that makes the client retry: p256 asks for a secp256r1 key share
# (our first one is x25519), cookie sends a HelloRetryRequest with a cookie; then
#   SSL_CERT_FILE=dir/ca.pem build/httpsGet localhost port /
d=$1; p=$2
if [ "$3" = cookie ]; then
  ( sleep 4; printf 'HTTP/1.1 200 OK\r\nContent-Length: 5\r\nConnection: close\r\n\r\nhello'; sleep 2; printf "Q\n" ) |
    timeout 30 openssl s_server -accept $p -cert $d/c18444.pem -key $d/k18444.pem -tls1_3 -stateless -naccept 1 -msg 2>&1
else
  timeout 30 openssl s_server -accept $p -cert $d/c18444.pem -key $d/k18444.pem -tls1_3 -groups P-256 -www -naccept 1 -msg 2>&1
fi
