#!/bin/bash

sudo apt update -y

wget https://downloads.mitmproxy.org/10.2.4/mitmproxy-10.2.4-linux-x86_64.tar.gz

tar -xvf mitmproxy-10.2.4-linux-x86_64.tar.gz

# # start the proxy

# ./mitmproxy

# sudo apt update -y

# sudo apt install python3-pip -y

# pip3 install mitmproxy

# mitmproxy --listen-port 8080 --web-host 0.0.0.0 --web-port 8081 --set block_global=false

sudo apt install wget -y

wget 'https://raw.githubusercontent.com/HoussemDellai/docker-kubernetes-course/main/_egress_proxy/certificate/mitmproxy-ca-cert.pem'
wget 'https://raw.githubusercontent.com/HoussemDellai/docker-kubernetes-course/main/_egress_proxy/certificate/mitmproxy-ca.pem'

mitmweb --listen-port 8080 --web-host 0.0.0.0 --web-port 8081 --set block_global=false --certs *=./mitmproxy-ca.pem --set confdir=./

# mitmweb --listen-port 8080 --web-host 0.0.0.0 --web-port 8081 --certs *=cert.pem --set block_global=false

# screen -d -m mitmweb --listen-port 8080 --web-host 0.0.0.0 --web-port 8081 --set block_global=false

# install the cert in: mitm.it


cat mitmproxy-ca-cert.pem | base64 -w0
# cat ~/.mitmproxy/mitmproxy-ca-cert.pem | base64 -w0