# Tips and tricks for Kubernetes and AKS

## Creaate an AKS cluster quickly

```sh
az group create -n rg-aks-cluster -l swedencentral

az aks create -n aks-cluster -g rg-aks-cluster --network-plugin azure --network-plugin-mode overlay -k 1.31.2 --node-vm-size standard_d2pds_v6

az aks get-credentials -n aks-cluster -g rg-aks-cluster --overwrite-existing
```

## Monitor Your cgroup Metrics

Linux cgroups provide detailed metrics about CPU usage and throttling. Look for the cpu.stat file within the container’s cgroup directory (usually under /sys/fs/cgroup):
Within the cpu.stat file there are three key metrics:

`nr_throttled`: Number of times the container was throttled.
`throttled_time`: Total time spent throttled – which I believe is in nanoseconds
`nr_periods`: Total CPU allocation periods.
Example:
    
```sh
cat /sys/fs/cgroup/cpu.stat
# Output:
# nr_periods 12345
# nr_throttled 543
# throttled_time 987654321
```

If `nr_throttled` or `throttled_time` is high relative to `nr_periods`, then you have CPU throttling on your container.

Src: https://dev.to/causely/tackling-cpu-throttling-in-kubernetes-for-better-application-performance-1dko
