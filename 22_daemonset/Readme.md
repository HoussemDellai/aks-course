### Introduction to DaemonSet

A DaemonSet is a Kubernetes object, just like the Deployment. But its objective is deploy a Pod into each Worker Node. Behind the scenes, it is using Node Affinity to place each Pod into a specific Node.

### Deploy a DaemonSet into Kubernetes

Lets deploy a sample DaemonSet that runs Nginx container:

```yaml
# daemonset.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: nginx
spec:
  selector:
    matchLabels:
      name: nginx
  template:
    metadata:
      labels:
        name: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
```

```sh
kubectl get nodes
kubectl apply daemonset.yaml
kubectl get daemonset
kubectl get pods -o wide
```

Note how a Pod is deployed into each Node.
But if we have System Nodepool with Taints, then the daemonSet won't be deployed there. Some additional steps are needed.

### Deploy DaemonSet to System Nodepool

A System Nodepool have (optionally) the following Taint:

```sh
kubectl get nodes
kubectl get node <aks-poolsystem-31734499-vmss000003> -o yaml # change with your node system name
```

```yaml
apiVersion: v1
kind: Node
metadata:
  name: aks-poolsystem-31734499-vmss000003
  uid: d3aa0585-33b2-42a0-95fe-5f5bede4eb4a
  resourceVersion: '1359886'
  creationTimestamp: '2022-09-25T11:21:43Z'
  labels:
    agentpool: poolsystem
    beta.kubernetes.io/arch: amd64
    beta.kubernetes.io/instance-type: Standard_D2ds_v5
    beta.kubernetes.io/os: linux
...
spec:
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
        effect: NoSchedule
```

Or add this one that will tolerate all Taints with effect: NoSchedule.

```yaml
      tolerations:
      - operator: Exists
        effect: NoSchedule
```

The DaemonSet should look like this:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: nginx
spec:
  selector:
    matchLabels:
      name: nginx
  template:
    metadata:
      labels:
        name: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
      tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
        effect: NoSchedule
      # - operator: Exists
      #   effect: NoSchedule
      # - key: node-role.kubernetes.io/control-plane
      #   operator: Exists
      #   effect: NoSchedule
      # - key: node-role.kubernetes.io/master
      #   operator: Exists
      #   effect: NoSchedule
      # - key: CriticalAddonsOnly
      #   operator: Exists
      # - operator: Exists
      #   effect: NoExecute
```

Then redeploy the Daemonset:

```sh
kubectl apply daemonset.yaml
kubectl get daemonset
kubectl get pods -o wide
```

Note that now the DaemonSet is deployed into the tainted System Nodepool.

Note alse the commented tolerations for deploying the DaemonSet into the Control Plane Nodes.
