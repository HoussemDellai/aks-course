<img src="images\architecture.png" style="background-color:white;">

```shell
# create an AKS cluster with Azure CNI network plugin

az group create -n rg-aks-cluster -l westeurope

az aks create -n aks-cluster -g rg-aks-cluster --network-plugin azure

# AKS by default uses 10.224.0.0/12 for VNET and 10.224.0.0/16 for Subnet

# enable Azure Application Gateway Ingress Controller

az aks addon enable -n aks-cluster -g rg-aks-cluster `
       --addon ingress-appgw `
       --appgw-subnet-cidr 10.225.0.0/16 `
       --appgw-name gateway

# connect to AKS cluster

az aks get-credentials -n aks-cluster -g rg-aks-cluster

kubectl get ingressclass
# NAME                        CONTROLLER                  PARAMETERS   AGE
# azure-application-gateway   azure/application-gateway   <none>       3h24m

kubectl apply -f ingress_appgw.yaml
# deployment.apps/aspnetapp created
# service/aspnetapp created
# ingress.networking.k8s.io/aspnetapp created

kubectl get pods,svc,ingress
# NAME                            READY   STATUS              RESTARTS   AGE
# pod/aspnetapp-bbcc5cf6c-4mtdc   1/1     Running             0          6s
# pod/aspnetapp-bbcc5cf6c-k8lqw   1/1     Running             0          6s
# pod/aspnetapp-bbcc5cf6c-x8r7z   0/1     ContainerCreating   0          6s

# NAME                 TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE
# service/aspnetapp    ClusterIP   10.0.115.64   <none>        80/TCP    6s
# service/kubernetes   ClusterIP   10.0.0.1      <none>        443/TCP   32m

# NAME                                  CLASS                       HOSTS   ADDRESS        PORTS   AGE
# ingress.networking.k8s.io/aspnetapp   azure-application-gateway   *       20.8.165.123   80      6s

kubectl get pods -o wide
# NAME                        READY   STATUS    RESTARTS   AGE   IP            NODE                             
# aspnetapp-bbcc5cf6c-4mtdc   1/1     Running   0          41s   10.224.0.85   aks-nodepool1-28007812-vmss000002
# aspnetapp-bbcc5cf6c-k8lqw   1/1     Running   0          41s   10.224.0.34   aks-nodepool1-28007812-vmss000000
# aspnetapp-bbcc5cf6c-x8r7z   1/1     Running   0          41s   10.224.0.28   aks-nodepool1-28007812-vmss000001
```