### Introduction to DaemonSet

A DaemonSet is a Kubernetes object, just like the Deployment. But its objective is deploy a Pod into each Worker Node. Behind the scenes, it is using Node Affinity to place each Pod into a specific Node.

### Deploy a DaemonSet into Kubernetes

Lets deploy a sample DaemonSet that runs Nginx container:

```bash
kubectl apply daemonset.yaml
kubectl get daemonset
kubectl get pods -o wide
```

Note how a Pod is deployed into each Node.
But if we have System Nodepool with Taints, then the daemonSet won't be deployed there. Some additional steps are needed.

### Deploy DaemonSet to System Nodepool

A System Nodepool have (optionally) the following Taint:

```yaml
  taints:
    - key: CriticalAddonsOnly
      value: 'true'
      effect: NoSchedule
```

Add Tolerations to the DaemonSet to be 'tolerated' to be deployed into the tainted Nodepool:

```yaml
      tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
      - operator: Exists
        effect: NoExecute
```

Or add this one that will tolerate all Taints with effect: NoSchedule.

```yaml
      tolerations:
      - operator: Exists
        effect: NoSchedule
```

The redeploy the Daemonset:

```bash
kubectl apply daemonset.yaml
kubectl get daemonset
kubectl get pods -o wide
```

Note that now the DaemonSet is deployed into the tainted System Nodepool.