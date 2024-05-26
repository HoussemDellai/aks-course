#!/bin/bash

# 1. install MITM proxy from official package

wget https://downloads.mitmproxy.org/10.3.0/mitmproxy-10.3.0-linux-x86_64.tar.gz

tar -xvf mitmproxy-10.3.0-linux-x86_64.tar.gz

# [Other option] install MITM proxy using Python pip

# sudo apt install python3-pip -y
# pip3 install mitmproxy
# sudo apt install wget -y # install if not installed

# MITM proxy can create a certificate for us on starting, but we will use our own certificate
# 2. download the certificate files

wget 'https://raw.githubusercontent.com/HoussemDellai/docker-kubernetes-course/main/67_egress_proxy/certificate/mitmproxy-ca-cert.pem'
wget 'https://raw.githubusercontent.com/HoussemDellai/docker-kubernetes-course/main/67_egress_proxy/certificate/mitmproxy-ca.pem'
wget 'https://raw.githubusercontent.com/HoussemDellai/docker-kubernetes-course/main/67_egress_proxy/certificate/mitmproxy-ca-cert.p12'

# 3. start MITM proxy with the certificate and expose the web interface

./mitmweb --listen-port 8080 --web-host 0.0.0.0 --web-port 8081 --set block_global=false --certs *=./mitmproxy-ca.pem --set confdir=./