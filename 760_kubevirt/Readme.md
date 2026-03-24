# Getting started with Kubevirt

## Creating an AKS cluster

Let's start by creating an AKS cluster in Azure. This cluster will be used to deploy and manage your applications.

```sh
az group create --name rg-aks-cluster --location swedencentral

az aks create -n aks-cluster -g rg-aks-cluster --network-plugin azure --network-plugin-mode overlay -k 1.33.3 --node-vm-size Standard_D4s_v5 --os-sku Ubuntu --node-osdisk-type Ephemeral --node-osdisk-size 64 --enable-apiserver-vnet-integration

az aks get-credentials -n aks-cluster -g rg-aks-cluster --overwrite-existing
```

## Install kubevirt

Check the latest version here:

```sh
curl -s https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt
# 1.7.2
```

Then install it with the command below (replace v1.7.2 with the latest version if needed):

```sh
# Get the latest release
export RELEASE=$(curl https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)

# Deploy the KubeVirt operator
curl -L https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-operator.yaml > kubevirt-operator.yaml
```

By default, KubeVirt sets the node-affinity of operator/custom resource components to control plane nodes. Because AKS control plane nodes are fully managed by Azure and inaccessible to KubeVirt, this update to utilize worker nodes avoids potential failures.

So at about line 8260 of the kubevirt-operator.yaml file, just remove the entire section of nodeAffinity and nodeSelector.

Then apply the operator:

```sh
kubectl apply -f kubevirt-operator.yaml
```

Now deploy the kubevirt-cr.yaml, which will create the KubeVirt custom resource and start the KubeVirt components:

```sh
curl -L https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-cr.yaml | yq '.spec.infra.nodePlacement={}' | kubectl apply -f -
```

Notice the empty nodePlacement: {} and the update for the node selector.

Check what is installed:

```sh
kubectl get pods -n kubevirt
# NAME                               READY   STATUS    RESTARTS   AGE
# virt-api-6cf697fb96-8lrc2          1/1     Running   0          5m7s
# virt-api-6cf697fb96-l2zdj          1/1     Running   0          3m56s
# virt-controller-6848bf9747-2swb4   1/1     Running   0          4m36s
# virt-controller-6848bf9747-w98tm   1/1     Running   0          4m36s
# virt-handler-8nvz5                 1/1     Running   0          4m36s
# virt-handler-fhm44                 1/1     Running   0          4m36s
# virt-handler-t8f7c                 1/1     Running   0          4m36s
# virt-operator-799577885c-4q7pw     1/1     Running   0          5m57s
# virt-operator-799577885c-kc8vs     1/1     Running   0          5m29s
```

## Deploy a VM

Creating VirtualMachineInstance resources in KubeVirt
With KubeVirt installed on your cluster, you can now create your VirtualMachineInstance (VMI) resources.

Create your VMI. Save the following YAML, which will create a VMI based on Fedora OS, as vmi-fedora.yaml. The username for this deployment will default to fedora, while you can specify a password of your choosing in password: <my_password>.

Deploy the VMI in your cluster.

```sh
kubectl apply -f vmi_fedora.yaml
```

## Check out the created VMI

Test and make sure the VMI is created and running.

```sh
kubectl get vmi
# NAME         AGE    PHASE     IP             NODENAME                            READY
# vmi-fedora   103s   Running   10.244.2.191   aks-nodepool1-34977713-vmss000002   True
```

Connect to the newly created VMI and inspect it.

```sh
virtctl console vmi-fedora
```

When prompted with credentials, the default username is fedora, while the password was configured in vmi-fedora.yaml.

vmi-fedora login: fedora
Password: 

Once logged in, run cat /etc/os-release to display the OS details.

[fedora@vmi-fedora ~]$ cat /etc/os-release
NAME=Fedora
VERSION="32 (Cloud Edition)"
ID=fedora
VERSION_ID=32
VERSION_CODENAME=""
PLATFORM_ID="platform:f32"
PRETTY_NAME="Fedora 32 (Cloud Edition)"
ANSI_COLOR="0;34"
LOGO=fedora-logo-icon
CPE_NAME="cpe:/o:fedoraproject:fedora:32"
HOME_URL="https://fedoraproject.org/"
DOCUMENTATION_URL="https://docs.fedoraproject.org/en-US/fedora/f32/system-administrators-guide/"
SUPPORT_URL="https://fedoraproject.org/wiki/Communicating_and_getting_help"
BUG_REPORT_URL="https://bugzilla.redhat.com/"
REDHAT_BUGZILLA_PRODUCT="Fedora"
REDHAT_BUGZILLA_PRODUCT_VERSION=32
REDHAT_SUPPORT_PRODUCT="Fedora"
REDHAT_SUPPORT_PRODUCT_VERSION=32
PRIVACY_POLICY_URL="https://fedoraproject.org/wiki/Legal:PrivacyPolicy"
VARIANT="Cloud Edition"
VARIANT_ID=cloud
```

## Resources

* https://blog.aks.azure.com/2026/02/06/kubevirt-on-aks