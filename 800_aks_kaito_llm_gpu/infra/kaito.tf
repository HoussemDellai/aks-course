# check new versions here: https://github.com/kaito-project/kaito/releases
locals {
  kaito_workspace_version = "0.9.1"
  kaito_ragengine_version = "0.9.1"
}

# Install the kaito-workspace chart
resource "helm_release" "kaito_workspace" {
  name             = "kaito-workspace"
  chart            = "https://raw.githubusercontent.com/kaito-project/kaito/refs/heads/gh-pages/charts/kaito/workspace-${local.kaito_workspace_version}.tgz"
  namespace        = "kaito-workspace"
  create_namespace = true

  set = [
    {
      name  = "clusterName"
      value = azurerm_kubernetes_cluster.aks.name
    },
    {
      name  = "defaultNodeImageFamily"
      value = "ubuntu"
    },
    {
      name  = "featureGates.gatewayAPIInferenceExtension"
      value = "true"
    },
    {
      name  = "featureGates.disableNodeAutoProvisioning"
      value = "false"
    },
    {
      name  = "gpu-feature-discovery.nfd.enabled"
      value = "true"
    },
    {
      name = "gpu-feature-discovery.gfd.enabled"
      value = "true"
    },
    {
      name  = "nvidiaDevicePlugin.enabled"
      value = "true"
    }
  ]

  depends_on = [azurerm_kubernetes_cluster_node_pool.nc24ads_a100_v4]
}

# Install the kaito-ragengine chart
resource "helm_release" "kaito_ragengine" {
  name             = "kaito-ragengine"
  chart            = "https://raw.githubusercontent.com/kaito-project/kaito/refs/heads/gh-pages/charts/kaito/ragengine-${local.kaito_ragengine_version}.tgz"
  namespace        = "kaito-ragengine"
  create_namespace = true
}

# # Install the gpu-provisioner chart
# Note: In this lab we are using Managed Node Pools GPU, which means that the GPU provisioner is installed by AKS itself, so we don't need the gpu-provisioner.
# resource "helm_release" "gpu_provisioner" {
#   name             = "gpu-provisioner"
#   chart            = "https://raw.githubusercontent.com/Azure/gpu-provisioner/refs/heads/gh-pages/charts/gpu-provisioner-${local.kaito_gpu_provisioner_version}.tgz"
#   namespace        = "gpu-provisioner"
#   create_namespace = true

#   values = [
#     templatefile("${path.module}/gpu-provisioner-values.tmpl",
#       {
#         AZURE_TENANT_ID          = data.azurerm_client_config.current.tenant_id
#         AZURE_SUBSCRIPTION_ID    = data.azurerm_client_config.current.subscription_id
#         RG_NAME                  = azurerm_resource_group.rg.name
#         LOCATION                 = azurerm_resource_group.rg.location
#         AKS_NAME                 = azurerm_kubernetes_cluster.aks.name
#         AKS_NRG_NAME             = azurerm_kubernetes_cluster.aks.node_resource_group
#         KAITO_IDENTITY_CLIENT_ID = azurerm_user_assigned_identity.kaito.client_id
#       }
#     )
#   ]
# }

# controller:
#   env:
#   - name: ARM_SUBSCRIPTION_ID
#     value: ${AZURE_SUBSCRIPTION_ID}
#   - name: LOCATION
#     value: ${LOCATION}
#   - name: AZURE_CLUSTER_NAME
#     value: ${AKS_NAME}
#   - name: AZURE_NODE_RESOURCE_GROUP
#     value: ${AKS_NRG_NAME}
#   - name: ARM_RESOURCE_GROUP
#     value: ${RG_NAME}
#   - name: LEADER_ELECT
#     value: "false"
# workloadIdentity:
#   clientId: ${KAITO_IDENTITY_CLIENT_ID}
#   tenantId: ${AZURE_TENANT_ID}
# settings:
#   azure:
#     clusterName: ${AKS_NAME}