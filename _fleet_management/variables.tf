variable "aks" {
  # type = list(string)
  default = [
    {
      cluster_name = "aks-cluster-1",
      version      = "1.29.2",
      os           = "AzureLinux", # | Ubuntu
      node_count   = 1
    },
    {
      cluster_name = "aks-cluster-2",
      version      = "1.29.0",
      os           = "Windows2022", # | Ubuntu
      node_count   = 2
    },
    {
      cluster_name = "aks-cluster-3",
      version      = "1.28.3",
      os           = "Ubuntu", # | Ubuntu
      node_count   = 2
    },
    {
      cluster_name = "aks-cluster-4",
      version      = "1.27.7",
      os           = "AzureLinux", # | Ubuntu
      node_count   = 1
    },
    {
      cluster_name = "aks-cluster-5",
      version      = "1.26.10",
      os           = "AzureLinux", # | Ubuntu
      node_count   = 1
    }
  ]
}