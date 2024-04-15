#!/bin/bash

sudo apt -qq update

# install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Kubectl CLI
snap install kubectl --classic

# Login to Azure using VM's Managed Identity
az login --identity

# az aks list -o table

# az aks get-credentials -n aks-cluster -g rg-spoke-203-001 --overwrite-existing

# kubectl get nodes