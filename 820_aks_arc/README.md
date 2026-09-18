# AKS connected to Azure Arc

Terraform creates three AKS clusters (`dev`, `ppr`, `prd`) with Azure CNI Overlay and the managed Cilium data plane and network policy engine. Each cluster is then connected to Azure Arc-enabled Kubernetes, including installation of the agents in the `azure-arc` namespace.

This is a disposable learning environment. `prd` is an environment label, not a production-ready configuration. AKS already has native Azure management; Arc onboarding here is for demonstrating Arc on existing Kubernetes clusters, not a requirement for managing AKS.

## Resources

Each environment has its own resource group, VNet, node subnet, user-assigned AKS identity, subnet-scoped Network Contributor assignment, AKS cluster and Arc connected-cluster resource. AKS also creates a managed node resource group. No VNet peering is configured.

| Environment | Node VNet | Node subnet | Overlay pods | Kubernetes services |
| --- | --- | --- | --- | --- |
| dev | 10.0.0.0/16 | 10.0.0.0/24 | 10.100.0.0/16 | 10.200.0.0/16 |
| ppr | 10.1.0.0/16 | 10.1.0.0/24 | 10.101.0.0/16 | 10.201.0.0/16 |
| prd | 10.2.0.0/16 | 10.2.0.0/24 | 10.102.0.0/16 | 10.202.0.0/16 |

Defaults: Sweden Central, AKS Free tier, one `Standard_D2as_v5` Azure Linux node per cluster, public API servers, Standard Load Balancer egress, OIDC and workload identity enabled. The AKS regional default Kubernetes version is selected at creation unless overridden. The three nodes need at least six regional/family vCPUs of quota, plus headroom for upgrades. Nodes, disks, public IPs and load balancers incur charges even without workloads.

## Prerequisites

- Terraform 1.14+, PowerShell 7 (`pwsh`), current Azure CLI (2.70+), and `kubectl` on PATH. PowerShell is also required when running from Linux or macOS.
- An Azure CLI login in the same subscription used by Terraform. Provider credentials alone do not authenticate the Arc CLI provisioner.
- Permission to create resource groups, AKS, networking, identities and Arc resources, register providers, and create role assignments. For this lab, Contributor plus Role Based Access Control Administrator at subscription scope covers these operations; use narrower delegated scopes where possible. The identity also needs permission to list AKS admin credentials.
- Region/VM availability and quota for all three clusters. Subscription policies must permit this demo's public endpoints and local AKS accounts.
- The runner must reach each Kubernetes API server. Nodes and the runner need the outbound access described in the [Arc network requirements](https://learn.microsoft.com/azure/azure-arc/kubernetes/network-requirements).

Terraform registers the core AzureRM providers plus `Microsoft.Kubernetes`, `Microsoft.KubernetesConfiguration` and `Microsoft.ExtendedLocation`. Registration is subscription-wide and requires permission. Where registration is centrally managed, have the administrator register these providers and set the provider registration configuration accordingly.

## Deploy

Run from this directory in PowerShell. The AzureRM provider is pinned to subscription `dcef7009-6b94-4382-afdc-17eb160d709a`; Arc onboarding derives the same subscription from that provider. Select it for the manual verification commands as well.

```powershell
az login
az account set --subscription dcef7009-6b94-4382-afdc-17eb160d709a
az account show --query '{name:name,id:id}' --output table
$env:ARM_SUBSCRIPTION_ID = "dcef7009-6b94-4382-afdc-17eb160d709a"
az extension add --name connectedk8s --upgrade

Copy-Item terraform.tfvars.example terraform.tfvars
terraform init
terraform validate
terraform plan -out=demo.tfplan
terraform apply -parallelism=1 demo.tfplan
terraform output clusters
```

Edit `terraform.tfvars` before planning to change `prefix`, `location`, `node_vm_size`, `node_count` or `kubernetes_version`. Use a unique prefix for another copy in the same subscription. Prefer setting `api_server_authorized_ip_ranges` to your runner's public egress CIDR (for example, your real public IPv4 address followed by `/32`). The default empty set leaves the API servers publicly reachable, with Kubernetes authentication still required. Include any other administrator egress ranges you need.

`-parallelism=1` serializes onboarding to avoid concurrent first-use initialization of the Arc CLI's shared Helm tooling. No separate manual connect step is required. Each `terraform_data.arc` provisioner obtains a temporary admin kubeconfig, runs `az connectedk8s connect`, waits for agent deployments, and deletes the temporary file even on failure. The default kubeconfig and active CLI subscription are not changed by the script. Both onboarding and destroy require the CLI login and API access.

The AzureRM provider cannot by itself perform this complete agent onboarding workflow, so Terraform orchestrates the documented CLI operation through `local-exec`. Arc resources are therefore **not refreshed for drift** by the provider: a normal plan cannot detect an externally deleted Arc connection or unhealthy agents. AKS resource dependencies ensure Arc disconnect runs before normal cluster destruction.

## Verify

```powershell
$clusters = terraform output -json clusters | ConvertFrom-Json
foreach ($environment in @('dev', 'ppr', 'prd')) {
    $cluster = $clusters.$environment
    az aks show --subscription $env:ARM_SUBSCRIPTION_ID -g $cluster.resource_group -n $cluster.aks_name --query 'networkProfile.{plugin:networkPlugin,mode:networkPluginMode,dataPlane:networkDataplane,policy:networkPolicy}' -o table
    az connectedk8s show --subscription $env:ARM_SUBSCRIPTION_ID -g $cluster.resource_group -n $cluster.arc_name --query '{name:name,status:connectivityStatus,provisioning:provisioningState}' -o table
}
```

Expect `azure`, `overlay`, `cilium`, `cilium` for networking, and eventually `Connected` / `Succeeded` for Arc. Arc metadata can take up to ten minutes to appear. The output also includes resource group portal URLs.

To inspect one cluster, the following explicitly adds an admin context to your normal kubeconfig:

```powershell
az aks get-credentials --subscription $env:ARM_SUBSCRIPTION_ID -g $clusters.dev.resource_group -n $clusters.dev.aks_name --admin
kubectl get pods -n kube-system -l k8s-app=cilium
kubectl get deployments,pods -n azure-arc
```

## Recovery And Cleanup

On an Arc failure, check Azure permissions, API access, outbound connectivity, and available node capacity. Terraform stops on CLI or agent readiness errors. It does not silently report a successful connection.

If onboarding partially succeeded, disconnect that environment using the script before retrying `terraform apply`. This also cleans up a tainted provisioner resource, whose destroy hook Terraform may skip. Substitute the affected environment and configured prefix:

```powershell
./scripts/arc.ps1 -Action Disconnect -SubscriptionId $env:ARM_SUBSCRIPTION_ID -ResourceGroup rg-aks-arc-dev -AksName aks-aks-arc-dev -ArcName arc-aks-arc-dev -Location swedencentral -Environment dev
terraform apply -parallelism=1
```

To repair externally deleted Arc registration, request a replacement of the corresponding onboarding resource:

```powershell
terraform apply '-replace=terraform_data.arc["dev"]' -parallelism=1
```

Destroy the demo while the clusters are still reachable:

```powershell
terraform destroy -parallelism=1
```

This removes Arc agents and connected-cluster resources first, then AKS and the remaining demo resources. Do not remove the Terraform configuration or manually delete AKS before destroying: the disconnect hook needs both the script and a reachable cluster. If a cluster was already deleted outside Terraform, follow the [Arc cleanup instructions](https://learn.microsoft.com/azure/azure-arc/kubernetes/quickstart-connect-cluster#clean-up-resources) to remove its stale registration, then retry destroy.

## Security And Scope

Local AKS admin accounts are intentionally enabled for a self-contained lab. The temporary admin credential is removed by the script, but AzureRM still stores cluster credentials in Terraform state. State and saved plans must be treated as secrets; they are ignored by Git here. Use encrypted remote state with access controls for shared use. Commit the provider lock file for reproducibility.

This demo does not add production availability zones, Entra-only Kubernetes access, private API endpoints, monitoring, ingress, applications, or Arc extensions. Production environments should use separate states and permissions, multiple nodes, appropriate paid tiers and a reviewed security design. Cilium supplies policy enforcement; no deny policies are installed by this demo.

## Offline Checks

```powershell
terraform fmt -check -recursive
terraform validate
terraform test
./tests/arc.Tests.ps1
```

Terraform tests use a mocked AzureRM provider and plan-only runs. Script tests mock Azure CLI and kubectl, including failures and temporary credential cleanup. Neither creates Azure resources; actual deployment, connectivity and teardown must still be verified against Azure.

## References

- [Azure CNI Overlay](https://learn.microsoft.com/azure/aks/azure-cni-overlay)
- [Azure CNI powered by Cilium](https://learn.microsoft.com/azure/aks/azure-cni-powered-by-cilium)
- [Connect Kubernetes to Azure Arc](https://learn.microsoft.com/azure/azure-arc/kubernetes/quickstart-connect-cluster)
- [AzureRM AKS resource](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster)
