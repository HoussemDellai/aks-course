
# AKS Connectivity Issue Reproduction – FULL Terraform Setup

## Overview
This package reproduces a suspected AKS platform networking issue using a production-like configuration.

## What is included
- Full AKS private cluster (Cilium + Azure CNI overlay)
- NAT Gateway outbound
- User-assigned managed identities
- RBAC + OIDC + Workload Identity
- DaemonSet test workload

## Deploy

```bash
terraform init
terraform apply -auto-approve
```

Get credentials:

```bash
az aks get-credentials   --resource-group jlephay-resourcegroup   --name jlephay-aks
```

Deploy test:

```bash
kubectl apply -f daemonset.yaml
```

Observe logs:

```bash
kubectl logs -n debug-network -l app=debug-network
```

Expected failure after time:
- curl (28) Resolving timed out
- curl (28) Connection timed out
