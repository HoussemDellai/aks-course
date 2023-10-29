# Azure Custom RBAC Role for AKS  
  
In this guide, we'll walk you through the steps of creating a custom Role-Based Access Control (RBAC) role for Azure Kubernetes Service (AKS). The custom RBAC role will allow you to control access to resources within your AKS cluster more granularly.  
  
## Prerequisites  
  
Ensure you have installed and configured:  
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)  
- [kubectl](https://kubernetes.io/docs/tasks/tools/)  
- [kubelogin](https://github.com/Azure/kubelogin)  
  
## Setting Up the Demo Environment  
  
Firstly, we'll set up a new AKS cluster in the Azure environment. Here are the steps.  

Define your resource group and AKS cluster names.

```sh
$AKS_RG="rg-aks-cluster"  
$AKS_NAME="aks-cluster"  
```

Create the resource group

```sh
az group create --name $AKS_RG --location westeurope  
```

Create the AKS cluster enabling Azure Active Directory (AAD) and Azure RBAC  

```sh
az aks create -n $AKS_NAME -g $AKS_RG --enable-aad --enable-azure-rbac  
```

Get the credentials of the AKS cluster  

```sh
az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing  
```

To verify your connection to the cluster, execute the following command:

```sh
kubectl get nodes  
```

You might encounter permission errors due to lack of necessary access rights. To fix this, update the role assignment:

```sh
$AKS_ID=$(az aks show -n $AKS_NAME -g $AKS_RG --query id -o tsv)  
$USER_ID=$(az ad signed-in-user show --query id -o tsv)  
```

Create a role assignment  

```sh
az role assignment create --role "Azure Kubernetes Service RBAC Writer" --assignee $USER_ID --scope $AKS_ID/namespaces/default  
```

## Creating a Custom Azure RBAC Role for AKS
 
The custom RBAC role will allow you to access resources in the kube-system namespace. Below is a sample role definition:

```json
{  
    "Name": "AKS Deployment Reader",  
    "Description": "Allows viewing all deployments in a cluster/namespace",  
    "Actions": [],  
    "NotActions": [],  
    "DataActions": ["Microsoft.ContainerService/managedClusters/apps/deployments/read"],  
    "NotDataActions": [],  
    "assignableScopes": ["/subscriptions/{subscription-id}"]  
}  
```

Replace {subscription-id} with your Azure subscription ID. Save this JSON as deployment-reader.json.

To create the role and assign it to the user, execute the following commands:

```sh
az role definition create --role-definition deployment-reader.json  
az role assignment create --role "AKS Deployment Reader" --assignee $USER_ID --scope $AKS_ID/namespaces/kube-system  
```

Please note that it might take up to 5 minutes for the role assignment to propagate across your AKS cluster.
Verifying the Custom Role
 
After the role has propagated, you should be able to list deployments in the kube-system namespace:

```sh
kubectl get deploy -n kube-system  
```

## Cleaning Up
 
Once you're done experimenting, you can clean up your resources to avoid unnecessary Azure charges:

```sh
az group delete -n $AKS_RG --yes --no-wait  
az role definition delete -n "AKS Deployment Reader"  
```

Congratulations! You've successfully created a custom RBAC role for AKS and assigned it to a user.