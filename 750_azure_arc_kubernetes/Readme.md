# Getting started with Azure ARC for Kubernetes

This project is a simple demonstration of how to use Azure Arc to manage a Kubernetes cluster. It includes a sample application that can be deployed to the cluster and managed through Azure Arc.

Topics:
* Monitoring Kubernetes clusters with Azure Monitor
* Enabling Workload Identity
* Deploying applications using GitOps with Azure Arc
* Using Azure Policy to enforce compliance on Kubernetes clusters
* Managing secrets with Azure Key Vault
* Setting up Azure Defender for Kubernetes
* Using Azure CLI and Azure PowerShell to manage Azure Arc resources
* Integrating Azure Storage

## Commands to enable extensions

Lets first define some common environment variables:

```sh
export clusterName="vm-ubuntu-k3s-francecentral-750-001"
export rgName="rg-arc-k8s-francecentral-750-001"
export prometheusResourceId="/subscriptions/dcef7009-6b94-4382-afdc-17eb160d709a/resourceGroups/rg-arc-k8s-francecentral-750/providers/Microsoft.Monitor/accounts/monitor-workspace-prometheus-750"
export grafanaResourceId="/subscriptions/dcef7009-6b94-4382-afdc-17eb160d709a/resourceGroups/rg-arc-k8s-francecentral-750/providers/Microsoft.Dashboard/grafana/grafana-750"
export logAnalyticsResourceId="/subscriptions/dcef7009-6b94-4382-afdc-17eb160d709a/resourceGroups/rg-arc-k8s-francecentral-750/providers/Microsoft.OperationalInsights/workspaces/log-analytics-750"
```

* Azure Monitor for Containers to collect metrics and send it to Managed Prometheus workspace and Grafana: 

```sh
az k8s-extension create -n azuremonitor-metrics \
   --cluster-name $clusterName \
   -g $rgName \
   --cluster-type connectedClusters \
   --extension-type Microsoft.AzureMonitor.Containers.Metrics \
   --configuration-settings azure-monitor-workspace-resource-id=$prometheusResourceId \
   --configuration-settings grafana-resource-id=$grafanaResourceId
```

Check the AMA-metrics agent was deployed successfully:

```sh
kubectl get pods -A
# NAMESPACE     NAME                                                  READY   STATUS    RESTARTS      AGE
# ... removed for brievity ...
# kube-system   azuremonitor-metrics-prometheus-node-exporter-llcww   1/1     Running   0             25m
# kube-system   ama-metrics-ksm-5dd95ddc94-7vb9t                      1/1     Running   0             25m
# kube-system   ama-metrics-operator-targets-777749d58-9b8bv          2/2     Running   1 (25m ago)   25m
# kube-system   ama-metrics-797468f4c9-8lcfr                          2/2     Running   1 (22m ago)   25m
# kube-system   ama-metrics-node-cz8nn                                2/2     Running   1 (22m ago)   25m
# kube-system   ama-metrics-797468f4c9-kp55d                          2/2     Running   1 (22m ago)   25m
```

It is also possible to customize settings for collecting logs en metrics by creating a ConfigMap as described here: https://raw.githubusercontent.com/microsoft/Docker-Provider/ci_prod/kubernetes/container-azm-ms-agentconfig.yaml

```sh
kubectl apply -f https://raw.githubusercontent.com/HoussemDellai/aks-course/refs/heads/main/750_azure_arc_kubernetes/k8s/container-azm-ms-agentconfig.yaml
```

>The configuration change can take a few minutes to finish before taking effect. Then all Azure Monitor Agent pods in the cluster will restart. The restart is a rolling restart for all Azure Monitor Agent pods, so not all of them restart at the same time.

You can now view metrics in the Managed Grafana workspace.

* Azure Monitor to collect logs and send it to Log Analytics workspace:

```sh
az k8s-extension create -n azuremonitor-containers \
   --cluster-name $clusterName \
   -g $rgName \
   --cluster-type connectedClusters \
   --extension-type Microsoft.AzureMonitor.Containers \
   --configuration-settings amalogs.useAADAuth=true \
   --configuration-settings logAnalyticsWorkspaceResourceID=$logAnalyticsResourceId
```

Check the AMA-logs agent was deployed successfully:

```sh
kubectl get pods -n kube-system
# NAME                                                  READY   STATUS    RESTARTS      AGE
# ... removed for brievity ...
# ama-logs-85qh6                                        3/3     Running   0             77s
# ama-logs-rs-55965cf96-xfxbh                           2/2     Running   0             77s
```

Let's deploy a pod that generates logs:

```sh
kubectl apply -f https://raw.githubusercontent.com/HoussemDellai/aks-course/refs/heads/main/750_azure_arc_kubernetes/k8s/logger-pod.yaml
```

You can check the logs of the pod:

```sh
kubectl logs logger
```

You can also view these logs on Log Analytics.

* Azure Key vault Secrets Store CSI Driver: 

```sh
az k8s-extension create -n akvsecretsprovider \
   --extension-type Microsoft.AzureKeyVaultSecretsProvider \
   --scope cluster \
   --cluster-name $clusterName \
   -g $rgName \
   --cluster-type connectedClusters
```

* Enable Workload Identity:

```sh
az connectedk8s update -n $clusterName \
   -g $rgName \
   --enable-oidc-issuer \
   --enable-workload-identity
```

Get the OIDC issuer URL:

```sh
az connectedk8s show -n vm-ubuntu-k3s-francecentral-750-001 \
   -g rg-arc-k8s-francecentral-750-001 \
   --query "oidcIssuerProfile.issuerUrl" \
   -o tsv
# https://europe.oic.prod-arc.azure.com/93139d1e-a3c1-4d78-9ed5-878be090eba4/49da22e6-9baa-4608-aea4-c5ce45ffab3c/
```

More details on how to use it with your apps here: https://learn.microsoft.com/en-us/azure/azure-arc/kubernetes/workload-identity

* Enable Azure RBAC on the cluster: 

Get the cluster MSI identity

```sh
az connectedk8s show -n $clusterName \
   -g $rgName \
   --query identity.principalId \
   -o tsv
# 203f77e4-d4e3-4274-95b7-a09abcce0d8d
```

Assign the `Connected Cluster Managed Identity CheckAccess Reader` role to the cluster MSI:

```sh
az role assignment create --role "Connected Cluster Managed Identity CheckAccess Reader" \
   --assignee "<Cluster MSI ID>" \
   --scope <cluster ARM ID>
```

Run this command from an account that have the `Owner` role on the subscription.

Example:

```sh
az role assignment create --role "Connected Cluster Managed Identity CheckAccess Reader" \
   --assignee "203f77e4-d4e3-4274-95b7-a09abcce0d8d" \
   --scope "/subscriptions/dcef7009-6b94-4382-afdc-17eb160d709a/resourceGroups/rg-arc-k8s-francecentral-750-001/providers/Microsoft.Kubernetes/connectedClusters/vm-ubuntu-k3s-francecentral-750-001"
```

Enable Azure role-based access control (RBAC) on your Azure Arc-enabled Kubernetes cluster:

```sh
az connectedk8s enable-features -n $clusterName \
   -g $rgName \
   --features azure-rbac
```

Assign Azure roles to users or groups to grant them access to the cluster. For example, to assign the `Azure Kubernetes Service RBAC Cluster Admin` role to a user:

```sh
az role assignment create --role "Azure Arc Kubernetes Cluster Admin" \
   --assignee <AZURE-AD-ENTITY-ID> \
   --scope $ARM_ID
```

Example:

```sh
az role assignment create --role "Azure Arc Kubernetes Cluster Admin" \
   --assignee "admin@MngEnvMCAP784683.onmicrosoft.com" \
   --scope "/subscriptions/dcef7009-6b94-4382-afdc-17eb160d709a/resourceGroups/rg-arc-k8s-francecentral-750-001/providers/Microsoft.Kubernetes/connectedClusters/vm-ubuntu-k3s-francecentral-750-001"
```

* Azure Policy: 

```sh

```

* Flux GitOps:

```sh
az k8s-configuration flux create -c $clusterName \
   -g $rgName \
   -n cluster-config \
   --namespace cluster-config \
   -t connectedClusters \
   --scope cluster \
   -u https://github.com/Azure/gitops-flux2-kustomize-helm-mt \
   --branch main  \
   --kustomization name=infra path=./infrastructure prune=true \
   --kustomization name=apps path=./apps/staging prune=true dependsOn=\["infra"\]
```

* Custom location:

```sh
az connectedk8s enable-features -n $clusterName \
   -g $rgName \
   --features cluster-connect custom-locations
```

Get the Azure Resource Manager identifier of the Azure Arc-enabled Kubernetes cluster

```sh
export connectedClusterId=$(az connectedk8s show -n $clusterName -g $rgName --query id -o tsv)
```

Get the Azure Resource Manager identifier of the cluster extension you deployed to the Azure Arc-enabled Kubernetes cluster

```sh
export extensionId=$(az k8s-extension show -c $clusterName -g $rgName --cluster-type connectedClusters -n <extensionInstanceName> --query id -o tsv)
```

Create the custom location by referencing the Azure Arc-enabled Kubernetes cluster and the extension

```sh
az customlocation create -n $clusterName -g $rgName$ --namespace customLocation001 --host-resource-id $connectedClusterId --cluster-extension-ids $extensionId
```

## Resources

* Terraform template was taken and modified from here: https://jumpstart.azure.com/azure_arc_jumpstart/azure_arc_k8s/rancher_k3s/azure_terraform