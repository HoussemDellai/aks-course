# Using StatefulSet in Kubernetes

## 0. Setup demo environment

```powershell
# variables
$AKS_RG="rg-aks-upgrade"
$AKS_NAME="aks-cluster"

# create and connect to AKS cluster
az group create --name $AKS_RG --location westeurope

az aks create --name $AKS_NAME `
              --resource-group $AKS_RG `
              --node-count 3

az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing

kubectl get nodes
# NAME                                STATUS   ROLES   AGE    VERSION
# aks-nodepool1-31334847-vmss000000   Ready    agent   6h8m   v1.23.12
# aks-nodepool1-31334847-vmss000001   Ready    agent   6h8m   v1.23.12
# aks-nodepool1-31334847-vmss000002   Ready    agent   6h9m   v1.23.12
```

## 1. Deploy statefulset, service and webapp

```powershell
# check the YAML manifest files in vs code
code app-deploy-svc.yaml
code db-statefulset-svc.yaml
```

Deploy the app

```powershell
kubectl apply -f .

kubectl get sts,pod,svc,pv,pvc
# NAME                              READY   AGE
# statefulset.apps/db-statefulset   1/1     50m

# NAME                                     READY   STATUS    RESTARTS   AGE
# pod/db-statefulset-0                     1/1     Running   0          50m
# pod/webapp-deployment-589d6cc6c8-vwspx   1/1     Running   0          50m

# NAME                     TYPE           CLUSTER-IP   EXTERNAL-IP   PORT(S)        AGE
# service/kubernetes       ClusterIP      10.0.0.1     <none>        443/TCP        5h44m
# service/mssql-service    ClusterIP      None         <none>        1433/TCP       50m
# service/webapp-service   LoadBalancer   10.0.0.121   20.4.177.91   80:31660/TCP   50m

# NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                           STORAGECLASS   REASON   AGE
# persistentvolume/pvc-c374ed8a-a489-49ae-8226-a2905ac51886   1Gi        RWO            Delete           Bound    default/data-db-statefulset-0   managed-csi             50m

# NAME                                          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# persistentvolumeclaim/data-db-statefulset-0   Bound    pvc-c374ed8a-a489-49ae-8226-a2905ac51886   1Gi        RWO            managed-csi    50m
```

## 2. Check app can connect to the database (browse to web app public IP)

check the database created successfully

```powershell
kubectl exec db-statefulset-0 -it -- ls /var/opt/mssql/data
# Entropy.bin  model_msdbdata.mdf          modellog.ldf  tempdb2.ndf
# master.mdf   model_msdblog.ldf           msdbdata.mdf  templog.ldf
# mastlog.ldf  model_replicatedmaster.ldf  msdblog.ldf
# model.mdf    model_replicatedmaster.mdf  tempdb.mdf
```

## 3. Check the created resources in Azure: Azure Disk (CSI) and Public IP.

## 4. check the DNS resolution for the headless service

```powershell
kubectl run nginx --image=nginx
kubectl exec nginx -it -- apt-get update
kubectl exec nginx -it -- apt-get install dnsutils

kubectl exec nginx -it -- nslookup mssql-service
# Server:         10.0.0.10
# Address:        10.0.0.10#53

# Name:   mssql-service.default.svc.cluster.local
# Address: 10.244.1.20
```

Note how each pod will have its own network identity

```powershell
kubectl exec nginx -it -- nslookup db-statefulset-0.mssql-service
# Server:         10.0.0.10
# Address:        10.0.0.10#53

# Name:   db-statefulset-0.mssql-service.default.svc.cluster.local
# Address: 10.244.1.22
```

## 5. Scale the StatefulSet

```powershell
kubectl scale --replicas=3 statefulset/db-statefulset
# statefulset.apps/db-statefulset scaled
```

Note how each replicas have its own PV and PVC

```powershell
kubectl get sts,pod,svc,pv,pvc
# NAME                              READY   AGE
# statefulset.apps/db-statefulset   3/3     54m

# NAME                                     READY   STATUS    RESTARTS   AGE
# pod/db-statefulset-0                     1/1     Running   0          54m
# pod/db-statefulset-1                     1/1     Running   0          2m33s
# pod/db-statefulset-2                     1/1     Running   0          2m14s
# pod/nginx                                1/1     Running   0          173m
# pod/webapp-deployment-589d6cc6c8-vwspx   1/1     Running   0          54m

# NAME                     TYPE           CLUSTER-IP   EXTERNAL-IP   PORT(S)        AGE
# service/kubernetes       ClusterIP      10.0.0.1     <none>        443/TCP        5h48m
# service/mssql-service    ClusterIP      None         <none>        1433/TCP       54m
# service/webapp-service   LoadBalancer   10.0.0.121   20.4.177.91   80:31660/TCP   54m

# NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                           STORAGECLASS   REASON   AGE
# persistentvolume/pvc-6da80163-c887-400e-acc8-0ee5ea9958df   1Gi        RWO            Delete           Bound    default/data-db-statefulset-1   managed-csi             2m30s
# persistentvolume/pvc-bc027108-e043-468f-bac0-a0a5edea6425   1Gi        RWO            Delete           Bound    default/data-db-statefulset-2   managed-csi             2m12s
# persistentvolume/pvc-c374ed8a-a489-49ae-8226-a2905ac51886   1Gi        RWO            Delete           Bound    default/data-db-statefulset-0   managed-csi             54m

# NAME                                          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# persistentvolumeclaim/data-db-statefulset-0   Bound    pvc-c374ed8a-a489-49ae-8226-a2905ac51886   1Gi        RWO            managed-csi    54m
# persistentvolumeclaim/data-db-statefulset-1   Bound    pvc-6da80163-c887-400e-acc8-0ee5ea9958df   1Gi        RWO            managed-csi    2m33s
# persistentvolumeclaim/data-db-statefulset-2   Bound    pvc-bc027108-e043-468f-bac0-a0a5edea6425   1Gi        RWO            managed-csi    2m15s
```

Each pod still have its own IP address and might be deployed in a different node.  
Note how each pod have well defined name, that name will be used later for DNS resolution to target a specific pod.

```powershell
kubectl get pods -o wide
# NAME                                 READY   STATUS    RESTARTS   AGE     IP            NODE                                NOMINATED NODE   READINESS GATES
# db-statefulset-0                     1/1     Running   0          55m     10.244.1.26   aks-nodepool1-31334847-vmss000001   <none>           <none>
# db-statefulset-1                     1/1     Running   0          3m48s   10.244.2.19   aks-nodepool1-31334847-vmss000000   <none>           <none>
# db-statefulset-2                     1/1     Running   0          3m29s   10.244.2.20   aks-nodepool1-31334847-vmss000000   <none>           <none>
# nginx                                1/1     Running   0          174m    10.244.2.11   aks-nodepool1-31334847-vmss000000   <none>           <none>
# webapp-deployment-589d6cc6c8-vwspx   1/1     Running   0          55m     10.244.1.25   aks-nodepool1-31334847-vmss000001   <none>           <none>
```

Note how the service resolves to the 3 IPs of the StatefulSet pods

```powershell
kubectl exec nginx -it -- nslookup mssql-service
# Server:         10.0.0.10
# Address:        10.0.0.10#53

# Name:   mssql-service.default.svc.cluster.local
# Address: 10.244.2.19
# Name:   mssql-service.default.svc.cluster.local
# Address: 10.244.1.26
# Name:   mssql-service.default.svc.cluster.local
# Address: 10.244.2.20
```

Note how each pod in the StatefulSet have its own DNS name

```powershell
kubectl exec nginx -it -- nslookup db-statefulset-0.mssql-service
# Server:         10.0.0.10
# Address:        10.0.0.10#53

# Name:   db-statefulset-0.mssql-service.default.svc.cluster.local
# Address: 10.244.1.26

kubectl exec nginx -it -- nslookup db-statefulset-1.mssql-service
# Server:         10.0.0.10
# Address:        10.0.0.10#53

# Name:   db-statefulset-1.mssql-service.default.svc.cluster.local
# Address: 10.244.2.19

kubectl exec nginx -it -- nslookup db-statefulset-2.mssql-service
# Server:         10.0.0.10
# Address:        10.0.0.10#53

# Name:   db-statefulset-2.mssql-service.default.svc.cluster.local
# Address: 10.244.2.20
```