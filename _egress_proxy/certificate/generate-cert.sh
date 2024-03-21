openssl genrsa -out cert.key 2048
# (Specify the mitm domain as Common Name, e.g. \*.google.com)
# openssl req -new -x509 -key cert.key -out cert.crt
# cat cert.key cert.crt > cert.pem

openssl req -new -x509 -key cert.key -out mitmproxy-ca-cert.pem
cat cert.key mitmproxy-ca-cert.pem > mitmproxy-ca.pem


openssl pkcs12 -export -inkey cert.key -in mitmproxy-ca-cert.pem -out mitmproxy-ca-cert.p12


cat mitmproxy-ca-cert.pem | base64 -w0