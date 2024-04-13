#!/bin/bash

sudo apt -qq update

# install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Kubectl CLI
snap install kubectl --classic

# az login -i

# az aks list -o table

# az aks get-credentials -n aks-cluster -g rg-spoke-101 --overwrite-existing

# kubectl get nodes