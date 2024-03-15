You can use your own (leaf) certificate by passing the --certs [domain=]path_to_certificate option to mitmproxy. Mitmproxy then uses the provided certificate for interception of the specified domain instead of generating a certificate signed by its own CA.

The certificate file is expected to be in the PEM format.

You can generate a certificate in this format using these instructions:

```sh
openssl genrsa -out cert.key 2048
# (Specify the mitm domain as Common Name, e.g. \*.google.com)
openssl req -new -x509 -key cert.key -out cert.crt
cat cert.key cert.crt > cert.pem
```