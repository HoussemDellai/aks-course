# AKS Backup with Terraform and Velero

## Introduction

## Architecture

![](images/architecture.png)

## Deploying the resources using Terraform

To deploy the Terraform configuration files, run the following commands:

```sh
terraform init

terraform plan -out tfplan

terraform apply tfplan
```

The following resources will be created.

![](images/resources.png)

## Cleanup resources

To delete the creates resources, run the following command:

```sh
terraform destroy
```

## More readings

https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/data_protection_backup_instance_kubernetes_cluster
