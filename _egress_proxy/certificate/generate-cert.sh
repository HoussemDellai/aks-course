openssl genrsa -out cert.key 2048
# (Specify the mitm domain as Common Name, e.g. \*.google.com)
openssl req -new -x509 -key cert.key -out cert.crt
cat cert.key cert.crt > cert.pem


cat cert.pem | base64 -w0