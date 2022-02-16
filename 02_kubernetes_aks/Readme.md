## Deploying Applications into Kubernetes/AKS

### Prerequisites:
1) Kubectl CLI: https://kubernetes.io/docs/tasks/tools/
2) AKS (or any Kubernetes) cluster
3) Owner or Contributor of an Azure subscription: http://azure.com/free

### Setting up the environment
1) Create an AKS cluster in Azure:
The creation of an AKS cluster could be achieved through one of these options: Azure portal, Azure CLI, Azure Powershell ARM templates, Bicep, Terraform, Ansible, Pulumi, Azure SDK and many more.
The simplest option is to use the portal as showed in this tutorial:
https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough-portal
Another simple option would be to use the Azure CLI:

```bash
 $ az group create --name myResourceGroup --location eastus
 $ az aks create --resource-group myResourceGroup --name myAKSCluster --node-count 3 --enable-addons monitoring --generate-ssh-keys
```

Next, the kubectl CLI will be used to deploy applications to the cluster. This command needs to be connected to AKS. To do that we use the following command:

```bash
 $ az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
```

Check that the connection was successfull by listing the nodes inside the cluster:

```bash
 $ kubectl get nodes
--------------------
NAME                       STATUS   ROLES   AGE     VERSION
aks-nodepool1-31718369-0   Ready    agent   6m44s   v1.12.8
```

### Wroking with Pods
Create an Nginx Pod:
```bash
 $ kubectl run nginx --image=nginx  
pod/nginx created 
```
List the existing pods:
```bash 
 $ kubectl get pods  
NAME    READY   STATUS    RESTARTS   AGE  
nginx   1/1     Running   0          10s  
```

View the private IP adress of the Pod and its host node.
```bash 
 $ kubectl get pods -o wide  
NAME    READY   STATUS    RESTARTS   AGE   IP             NODE                                NOMINATED NODE   READINESS GATES  
nginx   1/1     Running   0          49s   10.244.2.3   aks-agentpool-18451317-vmss000001   <none>           <none>
```

Create a Service object to expose the Pod through public IP and Load Balancer.
```bash 
 $ kubectl expose pod nginx --type=LoadBalancer --port=80
service/nginx exposed
```
 
 View the Service public IP.
```bash 
 $ kubectl get svc
NAME         TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)        AGE
kubernetes   ClusterIP      10.0.0.1      <none>          443/TCP        14m
nginx        LoadBalancer   10.0.147.78   20.61.145.135   80:32640/TCP   17s
```

## Deploying Images from ACR into AKS

### Create an Docker Registry in Azure (ACR)
Follow this link to create an ACR using the portal: https://docs.microsoft.com/en-us/azure/container-registry/container-registry-get-started-portal
Or this link to create it through the command line: https://docs.microsoft.com/en-us/azure/container-registry/container-registry-event-grid-quickstart
### Create an image in ACR
Navigate into the \app-dotnet folder and run the following command to package the source code, upload it into ACR and build the docker image inside ACR:
```bash 
$acrName="<myacr>"
az acr build -t "$acrName.azurecr.io/dotnet-app:1.0.0" -r $acrName .
```
 
Deploy the created image in ACR into the AKS cluster and replace image and registry names:
```bash 
 $ kubectl run dotnet-app --image=<houssemdellaiacr>.azurecr.io/dotnet-app:1.0.0
pod/dotnet-app created
```
 
```bash 
 $ kubectl get pods
NAME         READY   STATUS    RESTARTS   AGE
dotnet-app   1/1     Running   0          117s
nginx        1/1     Running   0          14m
```
 
```bash 
 $ kubectl expose pod dotnet-app --type=LoadBalancer --port=80
service/dotnet-app exposed
```
 
```bash 
 $ kubectl get svc
NAME         TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)        AGE
dotnet-app   LoadBalancer   10.0.202.46   <pending>       80:31774/TCP   10s
kubernetes   ClusterIP      10.0.0.1      <none>          443/TCP        26m
nginx        LoadBalancer   10.0.147.78   20.61.145.135   80:32640/TCP   12m
```
 
```bash 
 $ kubectl get svc
NAME         TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)        AGE
dotnet-app   LoadBalancer   10.0.202.46   <pending>       80:31774/TCP   24s
kubernetes   ClusterIP      10.0.0.1      <none>          443/TCP        26m
nginx        LoadBalancer   10.0.147.78   20.61.145.135   80:32640/TCP   12m
```
 
```bash 
 $ kubectl get svc -w
NAME         TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)        AGE
dotnet-app   LoadBalancer   10.0.202.46   52.142.237.17   80:31774/TCP   30s
kubernetes   ClusterIP      10.0.0.1      <none>          443/TCP        26m
nginx        LoadBalancer   10.0.147.78   20.61.145.135   80:32640/TCP   12m
```
Use the Kubectl command line to generate a YAML manifest for a Pod.
```bash 
 $ kubectl run nginx-yaml --restart=Never --image=nginx -o yaml --dry-run=client > nginx-pod.yaml
```
Deploy the YAML manifest to AKS:
```bash 
 $ kubectl apply -f .\nginx-pod.yaml
pod/nginx-yaml created
```
View the Pods created by YAML manifest.
```bash 
 $ kubectl get pods
NAME         READY   STATUS    RESTARTS   AGE
dotnet-app   1/1     Running   0          9m19s
nginx        1/1     Running   0          21m
nginx-yaml   1/1     Running   0          9s
```