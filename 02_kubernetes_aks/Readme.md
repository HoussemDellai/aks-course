 $ kubectl run nginx --image=nginx
pod/nginx created
 $
 $ kubectl get pods
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          10s
 $
 $ kubectl get pods -o wide
NAME    READY   STATUS    RESTARTS   AGE   IP           NODE                                NOMINATED NODE   READINESS GATES
nginx   1/1     Running   0          49s   10.244.2.3   aks-agentpool-18451317-vmss000001   <none>           <none>
 $
 $ kubectl expose pod nginx --type=LoadBalancer --port=80
service/nginx exposed
 $
 $ kubectl get svc
NAME         TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)        AGE
kubernetes   ClusterIP      10.0.0.1      <none>          443/TCP        14m
nginx        LoadBalancer   10.0.147.78   20.61.145.135   80:32640/TCP   17s

$acrName="houssemdellaiacr"

az acr build -t "$acrName.azurecr.io/dotnet-app:1.0.0" -r $acrName .

 $ kubectl run dotnet-app --image=houssemdellaiacr.azurecr.io/dotnet-app:1.0.0
pod/dotnet-app created
 $
 $ kubectl get pods
NAME         READY   STATUS    RESTARTS   AGE
dotnet-app   1/1     Running   0          117s
nginx        1/1     Running   0          14m
 $
 $ kubectl expose pod dotnet-app --type=LoadBalancer --port=80
service/dotnet-app exposed
 $
 $ kubectl get svc
NAME         TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)        AGE
dotnet-app   LoadBalancer   10.0.202.46   <pending>       80:31774/TCP   10s
kubernetes   ClusterIP      10.0.0.1      <none>          443/TCP        26m
nginx        LoadBalancer   10.0.147.78   20.61.145.135   80:32640/TCP   12m
 $
 $ kubectl get svc
NAME         TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)        AGE
dotnet-app   LoadBalancer   10.0.202.46   <pending>       80:31774/TCP   24s
kubernetes   ClusterIP      10.0.0.1      <none>          443/TCP        26m
nginx        LoadBalancer   10.0.147.78   20.61.145.135   80:32640/TCP   12m
 $
 $ kubectl get svc -w
NAME         TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)        AGE
dotnet-app   LoadBalancer   10.0.202.46   52.142.237.17   80:31774/TCP   30s
kubernetes   ClusterIP      10.0.0.1      <none>          443/TCP        26m
nginx        LoadBalancer   10.0.147.78   20.61.145.135   80:32640/TCP   12m

 $ kubectl run nginx-yaml --restart=Never --image=nginx -o yaml --dry-run=client > nginx-pod.yaml
 $
 $ kubectl apply -f .\nginx-pod.yaml
pod/nginx-yaml created
 $
 $ kubectl get pods
NAME         READY   STATUS    RESTARTS   AGE
dotnet-app   1/1     Running   0          9m19s
nginx        1/1     Running   0          21m
nginx-yaml   1/1     Running   0          9s