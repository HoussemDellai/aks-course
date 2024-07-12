# Working with Service Connector in AKS

## Introduction

Service Connector is a feature in AKS that allows you to connect to services running in your AKS cluster from outside the cluster. This is useful when you want to expose services running in your AKS cluster to external clients or services. In this guide, we will learn how to use Service Connector to connect to services running in an AKS cluster from outside the cluster.

## Prerequisites

## Creating the resources

```sh
az provider register -n Microsoft.ServiceLinker

az group create --name rg-aks-cluster --location swedencentral

az aks create -n aks-cluster -g rg-aks-cluster --network-plugin azure --network-plugin-mode overlay -k 1.29.4

# create azure storage account
az storage account create -n storaccountaks13 -g rg-aks-cluster -l swedencentral --sku Standard_LRS

# create a blob container
az storage container create -n container-aks --account-name storaccountaks13

# get Blob container resource ID into a variable
blobResId=$(az storage container show --name container-aks --account-name storaccountaks13 --query id -o tsv)

blobResId="/subscriptions/{subscription}/resourceGroups/{target_resource_group}/providers/Microsoft.Storage/storageAccounts/storaccountaks13/blobServices/container-aks"

az aks connection list-support-types --output table

az aks connection create storage-blob -h