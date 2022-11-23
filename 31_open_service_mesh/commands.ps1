# https://release-v1-2.docs.openservicemesh.io/docs/getting_started/install_apps/

# create an AKS cluster
RG="rg-aks-we"
AKS="aks-cluster"

az group create -n $RG -l westeurope

az aks create -g $RG -n $AKS --network-plugin azure --kubernetes-version "1.25.2" --node-count 2

az aks get-credentials --name $AKS -g $RG --overwrite-existing

# verify connection to the cluster
kubectl get nodes

$osm_namespace="osm-system" # Replace osm-system with the namespace where OSM will be installed
$osm_mesh_name="osm-demo" # Replace osm with the desired OSM mesh name

osm install `
    --mesh-name $osm_mesh_name `
    --osm-namespace $osm_namespace `
    --set=osm.enablePermissiveTrafficPolicy=true `
    --set=osm.deployPrometheus=true `
    --set=osm.deployGrafana=true `
    --set=osm.deployJaeger=true
# OSM installed successfully in namespace [osm-system] with mesh name [osm-demo]

kubectl get all -n $osm_namespace
# NAME                                  READY   STATUS      RESTARTS   AGE
# pod/jaeger-6fbc754dfd-xmtbm           1/1     Running     0          4m24s
# pod/osm-bootstrap-5d4f7899f7-n5mdh    1/1     Running     0          4m24s
# pod/osm-controller-5785474fdf-5746m   1/1     Running     0          4m24s
# pod/osm-grafana-766756f9b-7ddwr       1/1     Running     0          4m24s
# pod/osm-injector-766c74f674-xs2mx     1/1     Running     0          4m24s
# pod/osm-preinstall-l6cnj              0/1     Completed   0          8m41s
# pod/osm-prometheus-5bb4b9bf57-mnqwx   1/1     Running     0          4m24s

# NAME                     TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                       AGE
# service/jaeger           ClusterIP   10.0.178.66    <none>        9411/TCP                      4m24s
# service/osm-bootstrap    ClusterIP   10.0.233.133   <none>        9443/TCP,9091/TCP             4m24s
# service/osm-controller   ClusterIP   10.0.120.240   <none>        15128/TCP,9092/TCP,9091/TCP   4m24s
# service/osm-grafana      ClusterIP   10.0.172.182   <none>        3000/TCP                      4m24s
# service/osm-injector     ClusterIP   10.0.75.40     <none>        9090/TCP                      4m24s
# service/osm-prometheus   ClusterIP   10.0.149.45    <none>        7070/TCP                      4m24s
# service/osm-validator    ClusterIP   10.0.190.114   <none>        9093/TCP                      4m24s

# NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
# deployment.apps/jaeger           1/1     1            1           4m24s
# deployment.apps/osm-bootstrap    1/1     1            1           4m24s
# deployment.apps/osm-controller   1/1     1            1           4m24s
# deployment.apps/osm-grafana      1/1     1            1           4m24s
# deployment.apps/osm-injector     1/1     1            1           4m24s
# deployment.apps/osm-prometheus   1/1     1            1           4m24s

# NAME                                        DESIRED   CURRENT   READY   AGE
# replicaset.apps/jaeger-6fbc754dfd           1         1         1       4m24s
# replicaset.apps/osm-bootstrap-5d4f7899f7    1         1         1       4m24s
# replicaset.apps/osm-controller-5785474fdf   1         1         1       4m24s
# replicaset.apps/osm-grafana-766756f9b       1         1         1       4m24s
# replicaset.apps/osm-injector-766c74f674     1         1         1       4m24s
# replicaset.apps/osm-prometheus-5bb4b9bf57   1         1         1       4m24s

# NAME                       COMPLETIONS   DURATION   AGE
# job.batch/osm-preinstall   1/1           7s         8m41s

# Create the Namespaces 
kubectl create namespace bookstore
kubectl create namespace bookbuyer
kubectl create namespace bookthief
kubectl create namespace bookwarehouse

# Add the new namespaces to the OSM control plane
osm namespace add bookstore bookbuyer bookthief bookwarehouse --mesh-name $osm_mesh_name
# Namespace [bookstore] successfully added to mesh [osm-demo]
# Namespace [bookbuyer] successfully added to mesh [osm-demo]
# Namespace [bookthief] successfully added to mesh [osm-demo]
# Namespace [bookwarehouse] successfully added to mesh [osm-demo]

# Now each one of the four namespaces is labelled with openservicemesh.io/monitored-by: osm and also annotated with 
# openservicemesh.io/sidecar-injection: enabled. 
# The OSM Controller, noticing the label and annotation on these namespaces, will start injecting all new pods with Envoy sidecars.

# Create Pods, Services, ServiceAccounts
# Create the bookbuyer service account and deployment:
kubectl apply -f https://raw.githubusercontent.com/openservicemesh/osm-docs/release-v1.2/manifests/apps/bookbuyer.yaml
# serviceaccount/bookbuyer created
# deployment.apps/bookbuyer created

# Create the bookthief service account and deployment:
kubectl apply -f https://raw.githubusercontent.com/openservicemesh/osm-docs/release-v1.2/manifests/apps/bookthief.yaml
# serviceaccount/bookthief created
# deployment.apps/bookthief created

# Create the bookstore service account, service, and deployment:
kubectl apply -f https://raw.githubusercontent.com/openservicemesh/osm-docs/release-v1.2/manifests/apps/bookstore.yaml
# service/bookstore created
# service/bookstore-v1 created
# serviceaccount/bookstore created
# deployment.apps/bookstore created

# Create the bookwarehouse service account, service, and deployment:
kubectl apply -f https://raw.githubusercontent.com/openservicemesh/osm-docs/release-v1.2/manifests/apps/bookwarehouse.yaml
# serviceaccount/bookwarehouse created
# service/bookwarehouse created
# deployment.apps/bookwarehouse created

# Create the mysql service account, service, and stateful set:
kubectl apply -f https://raw.githubusercontent.com/openservicemesh/osm-docs/release-v1.2/manifests/apps/mysql.yaml
# serviceaccount/mysql created
# service/mysql created
# statefulset.apps/mysql created

# A Kubernetes Deployment and Pods for each of bookbuyer, bookthief, bookstore and bookwarehouse, and a StatefulSet for mysql. 
# Also, Kubernetes Services and Endpoints for bookstore, bookwarehouse, and mysql.
# To view these resources on your cluster, run the following commands:

kubectl get pods,deployments,serviceaccounts -n bookbuyer
# NAME                             READY   STATUS    RESTARTS   AGE
# pod/bookbuyer-5878d64f6f-lpjmw   2/2     Running   0          3m16s

# NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
# deployment.apps/bookbuyer   1/1     1            1           3m17s

# NAME                       SECRETS   AGE
# serviceaccount/bookbuyer   0         3m17s
# serviceaccount/default     0         16m

kubectl get pods,deployments,serviceaccounts -n bookthief
# NAME                             READY   STATUS    RESTARTS   AGE
# pod/bookthief-6d45d54fbd-6dsnm   2/2     Running   0          3m15s

# NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
# deployment.apps/bookthief   1/1     1            1           3m16s

# NAME                       SECRETS   AGE
# serviceaccount/bookthief   0         3m16s
# serviceaccount/default     0         16m

kubectl get pods,deployments,serviceaccounts,services,endpoints -n bookstore
# NAME                             READY   STATUS    RESTARTS   AGE
# pod/bookstore-784b6f9445-n4hwz   2/2     Running   0          3m16s

# NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
# deployment.apps/bookstore   1/1     1            1           3m16s

# NAME                       SECRETS   AGE
# serviceaccount/bookstore   0         3m16s
# serviceaccount/default     0         16m

# NAME                   TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)     AGE
# service/bookstore      ClusterIP   10.0.25.71     <none>        14001/TCP   3m17s
# service/bookstore-v1   ClusterIP   10.0.210.166   <none>        14001/TCP   3m16s

# NAME                     ENDPOINTS           AGE
# endpoints/bookstore      10.224.0.21:14001   3m17s
# endpoints/bookstore-v1   10.224.0.21:14001   3m16s

kubectl get pods,deployments,serviceaccounts,services,endpoints -n bookwarehouse
# NAME                                READY   STATUS    RESTARTS   AGE
# pod/bookwarehouse-d49bd5ff5-v8272   2/2     Running   0          3m17s
# pod/mysql-0                         3/3     Running   0          3m

# NAME                            READY   UP-TO-DATE   AVAILABLE   AGE
# deployment.apps/bookwarehouse   1/1     1            1           3m17s

# NAME                           SECRETS   AGE
# serviceaccount/bookwarehouse   0         3m17s
# serviceaccount/default         0         16m
# serviceaccount/mysql           0         3m

# NAME                    TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)     AGE
# service/bookwarehouse   ClusterIP   10.0.24.126   <none>        14001/TCP   3m17s
# service/mysql           ClusterIP   None          <none>        3306/TCP    3m

# NAME                      ENDPOINTS           AGE
# endpoints/bookwarehouse   10.224.0.50:14001   3m17s
# endpoints/mysql           10.224.0.16:3306    3m

# a Kubernetes Service Account was also created for each application. 
# The Service Account serves as the application’s identity which will be used later in the demo
# to create service-to-service access control policies.

# View the Application UIs

# $bookbuyer_pod=(kubectl get pods -n bookbuyer --output=json | jq '.' | jq -r '(.items[0].metadata.name)')
# echo $bookbuyer_pod
# # bookbuyer-5878d64f6f-lpjmw

# $bookstore_pod=(kubectl get pods -n bookstore --output=json | jq '.' | jq -r '(.items[0].metadata.name)')
# echo $bookstore_pod
# # bookstore-784b6f9445-n4hwz

# $bookthief_pod=(kubectl get pods -n bookthief --output=json | jq '.' | jq -r '(.items[0].metadata.name)')
# echo $bookthief_pod
# # bookthief-6d45d54fbd-6dsnm

kubectl port-forward deployment/bookbuyer 8080:14001 -n bookbuyer
kubectl port-forward deployment/bookthief 8083:14001 -n bookthief
kubectl port-forward deployment/bookstore 8084:14001 -n bookstore

# Check whether permissive traffic policy mode is enabled or not by retrieving the value for the enablePermissiveTrafficPolicyMode key
# in the osm-mesh-config MeshConfig resource.
kubectl get meshconfig osm-mesh-config -n osm-system -o jsonpath='{.spec.traffic.enablePermissiveTrafficPolicyMode}'
# true
# Output:
# false: permissive traffic policy mode is disabled, SMI policy mode is enabled
# true: permissive traffic policy mode is enabled, SMI policy mode is disabled

kubectl patch meshconfig osm-mesh-config -n osm-system -p '{"spec":{"traffic":{"enablePermissiveTrafficPolicyMode":false}}}' --type=merge
# meshconfig.config.openservicemesh.io/osm-mesh-config patched

kubectl apply -f https://raw.githubusercontent.com/openservicemesh/osm-docs/release-v1.2/manifests/access/traffic-access-v1.yaml
# traffictarget.access.smi-spec.io/bookstore created
# httproutegroup.specs.smi-spec.io/bookstore-service-routes created
# traffictarget.access.smi-spec.io/bookstore-access-bookwarehouse created
# httproutegroup.specs.smi-spec.io/bookwarehouse-service-routes created
# traffictarget.access.smi-spec.io/mysql created
# tcproute.specs.smi-spec.io/mysql created

kubectl apply -f https://raw.githubusercontent.com/openservicemesh/osm-docs/release-v1.2/manifests/access/traffic-access-v1-allow-bookthief.yaml
# traffictarget.access.smi-spec.io/bookstore configured
# httproutegroup.specs.smi-spec.io/bookstore-service-routes unchanged
# traffictarget.access.smi-spec.io/bookstore-access-bookwarehouse unchanged
# httproutegroup.specs.smi-spec.io/bookwarehouse-service-routes unchanged
# traffictarget.access.smi-spec.io/mysql unchanged
# tcproute.specs.smi-spec.io/mysql unchanged

osm metrics enable --namespace "bookstore, bookbuyer, bookthief, bookwarehouse"
# Metrics successfully enabled in namespace [bookstore]
# Metrics successfully enabled in namespace [bookbuyer]
# Metrics successfully enabled in namespace [bookthief]
# Metrics successfully enabled in namespace [bookwarehouse]

# The OSM Grafana dashboards can be viewed with the following command:
osm dashboard