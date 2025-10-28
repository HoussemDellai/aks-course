# Getting started with Kubevirt

## Creating an AKS cluster

Let's start by creating an AKS cluster in Azure. This cluster will be used to deploy and manage your applications.

```sh
az group create --name rg-aks-cluster --location francecentral

az aks create -n aks-cluster -g rg-aks-cluster --network-plugin azure --network-plugin-mode overlay -k 1.33.3 --node-vm-size standard_d4ads_v6 --os-sku Ubuntu --node-osdisk-type Ephemeral --node-osdisk-size 64 --enable-apiserver-vnet-integration

az aks get-credentials -n aks-cluster -g rg-aks-cluster --overwrite-existing
```

## Install kubevirt

Check the latest version here:

```sh
curl -s https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt
```

Then install it with the command below (replace v1.6.2 with the latest version if needed):

```sh
kubectl create -f "https://github.com/kubevirt/kubevirt/releases/download/v1.6.2/kubevirt-operator.yaml"

kubectl create -f "https://github.com/kubevirt/kubevirt/releases/download/v1.6.2/kubevirt-cr.yaml"
```

Check what is installed:

```sh
kubectl get all -n kubevirt
# NAME                                READY   STATUS    RESTARTS   AGE
# pod/virt-operator-d567bd999-qqgx9   1/1     Running   0          6m12s
# pod/virt-operator-d567bd999-wcr2g   1/1     Running   0          6m12s

# NAME                            READY   UP-TO-DATE   AVAILABLE   AGE
# deployment.apps/virt-operator   2/2     2            2           6m13s

# NAME                                      DESIRED   CURRENT   READY   AGE
# replicaset.apps/virt-operator-d567bd999   2         2         2       6m13s
```

## Deploy a VM

```sh
kubectl apply -f vm.yaml
```

