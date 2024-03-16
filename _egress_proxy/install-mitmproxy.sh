#!/bin/bash

# sudo apt update -y

# wget https://downloads.mitmproxy.org/10.2.2/mitmproxy-10.2.2-linux-x86_64.tar.gz

# tar -xvf mitmproxy-10.2.2-linux-x86_64.tar.gz

# # start the proxy; this is also needed to generate the certificates

# ./mitmproxy

sudo apt update -y

sudo apt install python3-pip -y

pip3 install mitmproxy

# mitmproxy --listen-port 8080 --web-host 0.0.0.0 --web-port 8081 --set block_global=false

sudo apt install wget -y

wget 'https://raw.githubusercontent.com/HoussemDellai/docker-kubernetes-course/main/_egress_proxy/certificate/cert.pem'

mitmweb --listen-port 8080 --web-host 0.0.0.0 --web-port 8081 --set block_global=false --certs *=cert.pem

# mitmweb --listen-port 8080 --web-host 0.0.0.0 --web-port 8081 --certs *=cert.pem --set block_global=false

# screen -d -m mitmweb --listen-port 8080 --web-host 0.0.0.0 --web-port 8081 --set block_global=false

# install the cert in: mitm.it