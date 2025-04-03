# Application Gateway for Containers with AKS

This demo showcases how to create an **Application Gateway for Containers (AGC)** integrated with **Azure Kubernetes Service (AKS)** to expose a sample application. The configuration uses **Terraform** to provision the required Azure resources and deploy the application.

## Architecture

The architecture includes:
- An AKS cluster hosting the sample application.
- An Application Gateway for Containers (AGC) to manage ingress traffic.
- A custom DNS zone for routing traffic to the application.
- A virtual network (VNet) for networking resources.

## Prerequisites

- Azure CLI installed and authenticated.
- Terraform CLI installed.
- An active Azure subscription.

## Terraform Configuration

The Terraform configuration is organized into multiple files for modularity:

### Resource Group
- **File:** `rg.tf`
- Creates a resource group to contain all resources.

### Virtual Network
- **File:** `vnet.tf`
- Provisions a virtual network and subnets for AKS and AGC.

### AKS Cluster
- **File:** `aks.tf`
- Deploys an AKS cluster with the necessary configurations.

### Application Gateway for Containers
- **File:** `install-alb.tf`
- Deploys the AGC and configures it to integrate with the AKS cluster.

### Managed Identity
- **File:** `identity-alb.tf`
- Creates a managed identity for AGC to interact with AKS.

### DNS Zone
- **File:** `dns_zone.tf`
- Configures a custom DNS zone for routing traffic to the application.

### Application Deployment
- **Folder:** `kubernetes/`
- Contains Kubernetes manifests:
  - `1-app.yaml`: Deploys the sample application (`inspectorgadget`) in the `webapp` namespace.
  - `2-ingress.yaml`: Configures an ingress resource to route traffic through AGC.

### Outputs
- **File:** `output.tf`
- Provides outputs such as the AGC frontend URL and AKS cluster details.

## Steps to Deploy

1. **Initialize Terraform**
   ```sh
   terraform init