# Resource Quota per priority class
kubectl create -f ./quota.yml
# resourcequota/pods-high created
# resourcequota/pods-medium created
# resourcequota/pods-low created

kubectl describe quota
# Name:       pods-high
# Namespace:  default
# Resource    Used  Hard
# --------    ----  ----
# cpu         0     1k
# memory      0     200Gi
# pods        0     10


# Name:       pods-low
# Namespace:  default
# Resource    Used  Hard
# --------    ----  ----
# cpu         0     5
# memory      0     10Gi
# pods        0     10


# Name:       pods-medium
# Namespace:  default
# Resource    Used  Hard
# --------    ----  ----
# cpu         0     10
# memory      0     20Gi
# pods        0     10

kubectl create -f ./high-priority-pod.yml

kubectl describe quota
# Name:       pods-high
# Namespace:  default
# Resource    Used  Hard
# --------    ----  ----
# cpu         500m  1k
# memory      10Gi  200Gi
# pods        1     10


# Name:       pods-low
# Namespace:  default
# Resource    Used  Hard
# --------    ----  ----
# cpu         0     5
# memory      0     10Gi
# pods        0     10


# Name:       pods-medium
# Namespace:  default
# Resource    Used  Hard
# --------    ----  ----
# cpu         0     10
# memory      0     20Gi
# pods        0     10

# Resource Quota with CPU and Memory

kubectl create namespace myspace

kubectl create -f ./compute-resources.yaml --namespace=myspace

kubectl create -f ./object-counts.yaml --namespace=myspace

kubectl get quota --namespace=myspace
# NAME                    AGE
# compute-resources       30s
# object-counts           32s

kubectl describe quota compute-resources --namespace=myspace
# Name:                    compute-resources
# Namespace:               myspace
# Resource                 Used  Hard
# --------                 ----  ----
# limits.cpu               0     2
# limits.memory            0     2Gi
# requests.cpu             0     1
# requests.memory          0     1Gi
# requests.nvidia.com/gpu  0     4

kubectl describe quota object-counts --namespace=myspace
# Name:                   object-counts
# Namespace:              myspace
# Resource                Used    Hard
# --------                ----    ----
# configmaps              0       10
# persistentvolumeclaims  0       4
# pods                    0       4
# replicationcontrollers  0       20
# secrets                 1       10
# services                0       10
# services.loadbalancers  0       2

# Kubectl also supports object count quota for all standard namespaced resources using the syntax count/<resource>.<group>:
kubectl create quota test --hard=count/deployments.apps=2,count/replicasets.apps=4,count/pods=3,count/secrets=4 --namespace=myspace

kubectl create deployment nginx --image=nginx --namespace=myspace --replicas=2

kubectl describe quota --namespace=myspace
# Name:                         test
# Namespace:                    myspace
# Resource                      Used  Hard
# --------                      ----  ----
# count/deployments.apps        1     2
# count/pods                    2     3
# count/replicasets.apps        1     4
# count/secrets                 1     4

# Cross-namespace Pod Affinity Quota
# Operators can use CrossNamespacePodAffinity quota scope to limit which namespaces are allowed to have pods with affinity terms that cross namespaces. Specifically, it controls which pods are allowed to set namespaces or namespaceSelector fields in pod affinity terms.
# Preventing users from using cross-namespace affinity terms might be desired since a pod with anti-affinity constraints can block pods from all other namespaces from getting scheduled in a failure domain.
# Using this scope operators can prevent certain namespaces (foo-ns in the example below) from having pods that use cross-namespace pod affinity by creating a resource quota object in that namespace with CrossNamespaceAffinity scope and hard limit of 0:

# apiVersion: v1
# kind: ResourceQuota
# metadata:
#   name: disable-cross-namespace-affinity
#   namespace: foo-ns
# spec:
#   hard:
#     pods: "0"
#   scopeSelector:
#     matchExpressions:
#     - scopeName: CrossNamespaceAffinity