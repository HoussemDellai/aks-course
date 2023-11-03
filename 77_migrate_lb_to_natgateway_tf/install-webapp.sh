#!/bin/bash

sudo apt -qq update

# Install curl and traceroute and jq
sudo apt -qq install curl traceroute inetutils-traceroute jq -y

# Install NGINX web server
sudo apt -qq install nginx -y

IP=$(hostname -i)

echo "Hello from virtual machine: $HOSTNAME, with IP address: $IP" > /var/www/html/index.html

# Script to force enable color prompt on Ubuntu and other Linux distros.
sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/g' ~/.bashrc

# Reload the .bashrc file
source ~/.bashrc