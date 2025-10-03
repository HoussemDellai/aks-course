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

* Azure Monitor for Containers to collect metrics and send it to Managed Prometheus workspace and Grafana: 

```sh
az k8s-extension create --name azuremonitor-metrics --cluster-name <cluster-name> --resource-group <resource-group> --cluster-type connectedClusters --extension-type Microsoft.AzureMonitor.Containers.Metrics --configuration-settings azure-monitor-workspace-resource-id=<workspace-name-resource-id> grafana-resource-id=<grafana-workspace-name-resource-id>

az k8s-extension create --name azuremonitor-metrics --cluster-name vm-linux-k3s --resource-group rg-arc-k8s-k3s-francecentral-750-001 --cluster-type connectedClusters --extension-type Microsoft.AzureMonitor.Containers.Metrics --configuration-settings azure-monitor-workspace-resource-id="/subscriptions/dcef7009-6b94-4382-afdc-17eb160d709a/resourceGroups/rg-arc-k8s-francecentral-750/providers/Microsoft.Monitor/accounts/monitor-workspace-prometheus-750" grafana-resource-id="/subscriptions/dcef7009-6b94-4382-afdc-17eb160d709a/resourceGroups/rg-arc-k8s-francecentral-750/providers/Microsoft.Dashboard/grafana/grafana-750"
```

* Azure Monitor to collect logs and send it to Log Analytics workspace:

```sh
az k8s-extension create --name azuremonitor-containers --cluster-name <cluster-name> --resource-group <resource-group> --cluster-type connectedClusters --extension-type Microsoft.AzureMonitor.Containers --configuration-settings amalogs.useAADAuth=true --configuration-settings logAnalyticsWorkspaceResourceID=<workspace-resource-id>
```

* Azure Key vault Secrets Store CSI Driver: 

```sh
az k8s-extension create --name akvsecretsprovider  --extension-type Microsoft.AzureKeyVaultSecretsProvider --scope cluster --cluster-name <clusterName> --resource-group <resourceGroupName> --cluster-type connectedClusters
```

* Azure Policy: 

```sh

```

## Resources

* Terraform template was taken and modified from here: https://jumpstart.azure.com/azure_arc_jumpstart/azure_arc_k8s/rancher_k3s/azure_terraform