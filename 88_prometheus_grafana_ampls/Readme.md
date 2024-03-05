# Private Azure Grafana, Prometheus and Log Analytics with AKS

## Introduction

With AKS, you can use `Azure Monitor Workspace for Prometheus` and `Azure Managed Grafana` to collect, query and visualize the metrics from AKS.
And to collect logs, you can use `Azure Log Analytics`.
These three resources comes with public endpoints, by default.
However, some customers requires all resources to be exposed only on private endpoints.

This lab will provide a private implementation for monitoring and logging.
It will use `Azure Monitor Private Link Scope (AMPLS)`.

## Architecture

![](images/architecture.png)

## Deploying the resources using Terraform

To deploy the Terraform configuration files, run the following commands:

```sh
terraform init

terraform plan -out tfplan

terraform apply tfplan
```

## Cleanup resources

To delete the creates resources, run the following command:

```sh
terraform destroy
```

## More readings

https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/azure-monitor-workspace-manage?tabs=azure-portal
