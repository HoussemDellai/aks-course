# Kubernetes Role and RoleBinding

## Introduction

Kubernetes exposes a REST API to manage its objects like pods, deployments, services, secrets, ingress, etc.
It uses the RBAC model to create and assign roles to users, groups and service accounts.

<img src="images/architecture.png"/>

## 0. Setup demo environment

```powershell
# Variables
$AKS_RG="rg-aks-serviceaccount"
$AKS_NAME="aks-cluster"

# Create and connect to AKS cluster
az group create --name $AKS_RG --location westeurope

az aks create --name $AKS_NAME --resource-group $AKS_RG --node-count 3 --zones 1 2 3 --kubernetes-version "1.25.2" --network-plugin azure

az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing

kubectl get nodes
# NAME                                STATUS   ROLES   AGE     VERSION
# aks-nodepool1-16995852-vmss000000   Ready    agent   3h31m   v1.25.2
# aks-nodepool1-16995852-vmss000001   Ready    agent   3h31m   v1.25.2
# aks-nodepool1-16995852-vmss000002   Ready    agent   3h31m   v1.25.2
```

## 1. Explore Kbernetes API Resources

<details><summary>kubectl api-resources</summary>

```powershell
kubectl api-resources
# NAME                              SHORTNAMES          APIVERSION                             NAMESPACED   KIND
# bindings                                              v1                                     true         Binding
# componentstatuses                 cs                  v1                                     false        ComponentStatus
# configmaps                        cm                  v1                                     true         ConfigMap
# endpoints                         ep                  v1                                     true         Endpoints
# events                            ev                  v1                                     true         Event
# limitranges                       limits              v1                                     true         LimitRange
# namespaces                        ns                  v1                                     false        Namespace
# nodes                             no                  v1                                     false        Node
# persistentvolumeclaims            pvc                 v1                                     true         PersistentVolumeClaim
# persistentvolumes                 pv                  v1                                     false        PersistentVolume
# pods                              po                  v1                                     true         Pod
# podtemplates                                          v1                                     true         PodTemplate
# replicationcontrollers            rc                  v1                                     true         ReplicationController
# resourcequotas                    quota               v1                                     true         ResourceQuota
# secrets                                               v1                                     true         Secret
# serviceaccounts                   sa                  v1                                     true         ServiceAccount
# services                          svc                 v1                                     true         Service
# mutatingwebhookconfigurations                         admissionregistration.k8s.io/v1        false        MutatingWebhookConfiguration
# validatingwebhookconfigurations                       admissionregistration.k8s.io/v1        false        ValidatingWebhookConfiguration
# customresourcedefinitions         crd,crds            apiextensions.k8s.io/v1                false        CustomResourceDefinition
# apiservices                                           apiregistration.k8s.io/v1              false        APIService
# controllerrevisions                                   apps/v1                                true         ControllerRevision
# daemonsets                        ds                  apps/v1                                true         DaemonSet
# deployments                       deploy              apps/v1                                true         Deployment
# replicasets                       rs                  apps/v1                                true         ReplicaSet
# statefulsets                      sts                 apps/v1                                true         StatefulSet
# tokenreviews                                          authentication.k8s.io/v1               false        TokenReview
# localsubjectaccessreviews                             authorization.k8s.io/v1                true         LocalSubjectAccessReview
# selfsubjectaccessreviews                              authorization.k8s.io/v1                false        SelfSubjectAccessReview
# selfsubjectrulesreviews                               authorization.k8s.io/v1                false        SelfSubjectRulesReview
# subjectaccessreviews                                  authorization.k8s.io/v1                false        SubjectAccessReview
# horizontalpodautoscalers          hpa                 autoscaling/v2                         true         HorizontalPodAutoscaler
# cronjobs                          cj                  batch/v1                               true         CronJob
# jobs                                                  batch/v1                               true         Job
# certificatesigningrequests        csr                 certificates.k8s.io/v1                 false        CertificateSigningRequest
# leases                                                coordination.k8s.io/v1                 true         Lease
# endpointslices                                        discovery.k8s.io/v1                    true         EndpointSlice
# events                            ev                  events.k8s.io/v1                       true         Event
# flowschemas                                           flowcontrol.apiserver.k8s.io/v1beta2   false        FlowSchema
# prioritylevelconfigurations                           flowcontrol.apiserver.k8s.io/v1beta2   false        PriorityLevelConfiguration
# nodes                                                 metrics.k8s.io/v1beta1                 false        NodeMetrics
# pods                                                  metrics.k8s.io/v1beta1                 true         PodMetrics
# ingressclasses                                        networking.k8s.io/v1                   false        IngressClass
# ingresses                         ing                 networking.k8s.io/v1                   true         Ingress
# networkpolicies                   netpol              networking.k8s.io/v1                   true         NetworkPolicy
# runtimeclasses                                        node.k8s.io/v1                         false        RuntimeClass
# poddisruptionbudgets              pdb                 policy/v1                              true         PodDisruptionBudget
# clusterrolebindings                                   rbac.authorization.k8s.io/v1           false        ClusterRoleBinding
# clusterroles                                          rbac.authorization.k8s.io/v1           false        ClusterRole
# rolebindings                                          rbac.authorization.k8s.io/v1           true         RoleBinding
# roles                                                 rbac.authorization.k8s.io/v1           true         Role
# priorityclasses                   pc                  scheduling.k8s.io/v1                   false        PriorityClass
# volumesnapshotclasses             vsclass,vsclasses   snapshot.storage.k8s.io/v1             false        VolumeSnapshotClass
# volumesnapshotcontents            vsc,vscs            snapshot.storage.k8s.io/v1             false        VolumeSnapshotContent
# volumesnapshots                   vs                  snapshot.storage.k8s.io/v1             true         VolumeSnapshot
# csidrivers                                            storage.k8s.io/v1                      false        CSIDriver
# csinodes                                              storage.k8s.io/v1                      false        CSINode
# csistoragecapacities                                  storage.k8s.io/v1                      true         CSIStorageCapacity
# storageclasses                    sc                  storage.k8s.io/v1                      false        StorageClass
# volumeattachments                                     storage.k8s.io/v1                      false        VolumeAttachment
```
</details>

View Kubernetes existing roles

<details><summary>kubectl get roles -A</summary>

```powershell
kubectl get roles -A
# NAMESPACE     NAME                                             CREATED AT
# kube-public   system:controller:bootstrap-signer               2023-01-01T17:52:17Z
# kube-system   extension-apiserver-authentication-reader        2023-01-01T17:52:17Z
# kube-system   system::leader-locking-kube-controller-manager   2023-01-01T17:52:17Z
# kube-system   system::leader-locking-kube-scheduler            2023-01-01T17:52:17Z
# kube-system   system:controller:bootstrap-signer               2023-01-01T17:52:17Z
# kube-system   system:controller:cloud-provider                 2023-01-01T17:52:17Z
# kube-system   system:controller:token-cleaner                  2023-01-01T17:52:17Z
# kube-system   system:metrics-server                            2023-01-01T17:52:40Z
```
</details>

<details><summary>kubectl get clusterroles -A</summary>

```powershell
kubectl get clusterroles -A
# NAME                                                                   CREATED AT
# admin                                                                  2023-01-01T17:52:15Z
# aks-service                                                            2023-01-01T17:52:39Z
# cloud-node-manager                                                     2023-01-01T17:52:39Z
# cluster-admin                                                          2023-01-01T17:52:15Z
# container-health-log-reader                                            2023-01-01T17:52:39Z
# csi-azuredisk-node-role                                                2023-01-01T17:52:39Z
# csi-azurefile-node-secret-role                                         2023-01-01T17:52:39Z
# edit                                                                   2023-01-01T17:52:15Z
# system:aggregate-to-admin                                              2023-01-01T17:52:15Z
# system:aggregate-to-edit                                               2023-01-01T17:52:16Z
# system:aggregate-to-view                                               2023-01-01T17:52:16Z
# system:auth-delegator                                                  2023-01-01T17:52:16Z
# system:azure-cloud-provider                                            2023-01-01T17:52:39Z
# system:azure-cloud-provider-secret-getter                              2023-01-01T17:52:39Z
# system:basic-user                                                      2023-01-01T17:52:15Z
# system:certificates.k8s.io:certificatesigningrequests:nodeclient       2023-01-01T17:52:16Z
# system:certificates.k8s.io:certificatesigningrequests:selfnodeclient   2023-01-01T17:52:16Z
# system:certificates.k8s.io:kube-apiserver-client-approver              2023-01-01T17:52:16Z
# system:certificates.k8s.io:kube-apiserver-client-kubelet-approver      2023-01-01T17:52:16Z
# system:certificates.k8s.io:kubelet-serving-approver                    2023-01-01T17:52:16Z
# system:certificates.k8s.io:legacy-unknown-approver                     2023-01-01T17:52:16Z
# system:controller:attachdetach-controller                              2023-01-01T17:52:16Z
# system:controller:certificate-controller                               2023-01-01T17:52:16Z
# system:controller:clusterrole-aggregation-controller                   2023-01-01T17:52:16Z
# system:controller:cronjob-controller                                   2023-01-01T17:52:16Z
# system:controller:daemon-set-controller                                2023-01-01T17:52:16Z
# system:controller:deployment-controller                                2023-01-01T17:52:16Z
# system:controller:disruption-controller                                2023-01-01T17:52:16Z
# system:controller:endpoint-controller                                  2023-01-01T17:52:16Z
# system:controller:endpointslice-controller                             2023-01-01T17:52:16Z
# system:controller:endpointslicemirroring-controller                    2023-01-01T17:52:16Z
# system:controller:ephemeral-volume-controller                          2023-01-01T17:52:16Z
# system:controller:expand-controller                                    2023-01-01T17:52:16Z
# system:controller:generic-garbage-collector                            2023-01-01T17:52:16Z
# system:controller:horizontal-pod-autoscaler                            2023-01-01T17:52:16Z
# system:controller:job-controller                                       2023-01-01T17:52:16Z
# system:controller:namespace-controller                                 2023-01-01T17:52:16Z
# system:controller:node-controller                                      2023-01-01T17:52:16Z
# system:controller:persistent-volume-binder                             2023-01-01T17:52:16Z
# system:controller:pod-garbage-collector                                2023-01-01T17:52:16Z
# system:controller:pv-protection-controller                             2023-01-01T17:52:16Z
# system:controller:pvc-protection-controller                            2023-01-01T17:52:16Z
# system:controller:replicaset-controller                                2023-01-01T17:52:16Z
# system:controller:replication-controller                               2023-01-01T17:52:16Z
# system:controller:resourcequota-controller                             2023-01-01T17:52:16Z
# system:controller:root-ca-cert-publisher                               2023-01-01T17:52:16Z
# system:controller:route-controller                                     2023-01-01T17:52:16Z
# system:controller:service-account-controller                           2023-01-01T17:52:16Z
# system:controller:service-controller                                   2023-01-01T17:52:16Z
# system:controller:statefulset-controller                               2023-01-01T17:52:16Z
# system:controller:ttl-after-finished-controller                        2023-01-01T17:52:16Z
# system:controller:ttl-controller                                       2023-01-01T17:52:16Z
# system:coredns                                                         2023-01-01T17:52:39Z
# system:coredns-autoscaler                                              2023-01-01T17:52:39Z
# system:discovery                                                       2023-01-01T17:52:15Z
# system:heapster                                                        2023-01-01T17:52:16Z
# system:kube-aggregator                                                 2023-01-01T17:52:16Z
# system:kube-controller-manager                                         2023-01-01T17:52:16Z
# system:kube-dns                                                        2023-01-01T17:52:16Z
# system:kube-scheduler                                                  2023-01-01T17:52:16Z
# system:kubelet-api-admin                                               2023-01-01T17:52:16Z
# system:metrics-server                                                  2023-01-01T17:52:40Z
# system:monitoring                                                      2023-01-01T17:52:15Z
# system:node                                                            2023-01-01T17:52:16Z
# system:node-bootstrapper                                               2023-01-01T17:52:16Z
# system:node-problem-detector                                           2023-01-01T17:52:16Z
# system:node-proxier                                                    2023-01-01T17:52:16Z
# system:persistent-volume-provisioner                                   2023-01-01T17:52:16Z
# system:persistent-volume-secret-operator                               2023-01-01T17:52:40Z
# system:prometheus                                                      2023-01-01T17:54:51Z
# system:public-info-viewer                                              2023-01-01T17:52:15Z
# system:service-account-issuer-discovery                                2023-01-01T17:52:16Z
# system:volume-scheduler                                                2023-01-01T17:52:16Z
# view                                                                   2023-01-01T17:52:15Z
```
</details>

View Kubernetes existing rolebindings

<details><summary>kubectl get rolebindings -A</summary>

```powershell
kubectl get rolebindings -A
# NAMESPACE     NAME                                                ROLE                                                  AGE
# default       pod-reader-binding                                  Role/pod-reader                                       11m
# kube-public   system:controller:bootstrap-signer                  Role/system:controller:bootstrap-signer               3h40m
# kube-system   metrics-server-auth-reader                          Role/extension-apiserver-authentication-reader        3h39m
# kube-system   metrics-server-binding                              Role/system:metrics-server                            3h39m
# kube-system   system::extension-apiserver-authentication-reader   Role/extension-apiserver-authentication-reader        3h40m
# kube-system   system::leader-locking-kube-controller-manager      Role/system::leader-locking-kube-controller-manager   3h40m
# kube-system   system::leader-locking-kube-scheduler               Role/system::leader-locking-kube-scheduler            3h40m
# kube-system   system:controller:bootstrap-signer                  Role/system:controller:bootstrap-signer               3h40m
# kube-system   system:controller:cloud-provider                    Role/system:controller:cloud-provider                 3h40m
# kube-system   system:controller:token-cleaner                     Role/system:controller:token-cleaner                  3h40m
```
</details>

<details><summary>kubectl get clusterrolebindings -A</summary>

```powershell
kubectl get clusterrolebindings -A
# NAME                                                   ROLE                                                                               AGE
# aks-cluster-admin-binding                              ClusterRole/cluster-admin                                                          3h40m
# aks-service-rolebinding                                ClusterRole/aks-service                                                            3h40m
# auto-approve-csrs-for-group                            ClusterRole/system:certificates.k8s.io:certificatesigningrequests:nodeclient       3h40m
# auto-approve-renewals-for-nodes                        ClusterRole/system:certificates.k8s.io:certificatesigningrequests:selfnodeclient   3h40m
# cloud-node-manager                                     ClusterRole/cloud-node-manager                                                     3h40m
# cluster-admin                                          ClusterRole/cluster-admin                                                          3h40m
# container-health-read-logs-global                      ClusterRole/container-health-log-reader                                            3h40m
# create-csrs-for-bootstrapping                          ClusterRole/system:node-bootstrapper                                               3h40m
# csi-azuredisk-node-binding                             ClusterRole/csi-azuredisk-node-role                                                3h40m
# csi-azurefile-node-secret-binding                      ClusterRole/csi-azurefile-node-secret-role                                         3h40m
# metrics-server:system:auth-delegator                   ClusterRole/system:auth-delegator                                                  3h40m
# system:aks-client-node-proxier                         ClusterRole/system:node-proxier                                                    3h40m
# system:aks-client-nodes                                ClusterRole/system:node                                                            3h40m
# system:azure-cloud-provider                            ClusterRole/system:azure-cloud-provider                                            3h40m
# system:azure-cloud-provider-secret-getter              ClusterRole/system:azure-cloud-provider-secret-getter                              3h40m
# system:basic-user                                      ClusterRole/system:basic-user                                                      3h40m
# system:controller:attachdetach-controller              ClusterRole/system:controller:attachdetach-controller                              3h40m
# system:controller:certificate-controller               ClusterRole/system:controller:certificate-controller                               3h40m
# system:controller:clusterrole-aggregation-controller   ClusterRole/system:controller:clusterrole-aggregation-controller                   3h40m
# system:controller:cronjob-controller                   ClusterRole/system:controller:cronjob-controller                                   3h40m
# system:controller:daemon-set-controller                ClusterRole/system:controller:daemon-set-controller                                3h40m
# system:controller:deployment-controller                ClusterRole/system:controller:deployment-controller                                3h40m
# system:controller:disruption-controller                ClusterRole/system:controller:disruption-controller                                3h40m
# system:controller:endpoint-controller                  ClusterRole/system:controller:endpoint-controller                                  3h40m
# system:controller:endpointslice-controller             ClusterRole/system:controller:endpointslice-controller                             3h40m
# system:controller:endpointslicemirroring-controller    ClusterRole/system:controller:endpointslicemirroring-controller                    3h40m
# system:controller:ephemeral-volume-controller          ClusterRole/system:controller:ephemeral-volume-controller                          3h40m
# system:controller:expand-controller                    ClusterRole/system:controller:expand-controller                                    3h40m
# system:controller:generic-garbage-collector            ClusterRole/system:controller:generic-garbage-collector                            3h40m
# system:controller:horizontal-pod-autoscaler            ClusterRole/system:controller:horizontal-pod-autoscaler                            3h40m
# system:controller:job-controller                       ClusterRole/system:controller:job-controller                                       3h40m
# system:controller:namespace-controller                 ClusterRole/system:controller:namespace-controller                                 3h40m
# system:controller:node-controller                      ClusterRole/system:controller:node-controller                                      3h40m
# system:controller:persistent-volume-binder             ClusterRole/system:controller:persistent-volume-binder                             3h40m
# system:controller:pod-garbage-collector                ClusterRole/system:controller:pod-garbage-collector                                3h40m
# system:controller:pv-protection-controller             ClusterRole/system:controller:pv-protection-controller                             3h40m
# system:controller:pvc-protection-controller            ClusterRole/system:controller:pvc-protection-controller                            3h40m
# system:controller:replicaset-controller                ClusterRole/system:controller:replicaset-controller                                3h40m
# system:controller:replication-controller               ClusterRole/system:controller:replication-controller                               3h40m
# system:controller:resourcequota-controller             ClusterRole/system:controller:resourcequota-controller                             3h40m
# system:controller:root-ca-cert-publisher               ClusterRole/system:controller:root-ca-cert-publisher                               3h40m
# system:controller:route-controller                     ClusterRole/system:controller:route-controller                                     3h40m
# system:controller:service-account-controller           ClusterRole/system:controller:service-account-controller                           3h40m
# system:controller:service-controller                   ClusterRole/system:controller:service-controller                                   3h40m
# system:controller:statefulset-controller               ClusterRole/system:controller:statefulset-controller                               3h40m
# system:controller:ttl-after-finished-controller        ClusterRole/system:controller:ttl-after-finished-controller                        3h40m
# system:controller:ttl-controller                       ClusterRole/system:controller:ttl-controller                                       3h40m
# system:coredns                                         ClusterRole/system:coredns                                                         3h40m
# system:coredns-autoscaler                              ClusterRole/system:coredns-autoscaler                                              3h40m
# system:discovery                                       ClusterRole/system:discovery                                                       3h40m
# system:kube-controller-manager                         ClusterRole/system:kube-controller-manager                                         3h40m
# system:kube-dns                                        ClusterRole/system:kube-dns                                                        3h40m
# system:kube-proxy                                      ClusterRole/system:node-proxier                                                    3h40m
# system:kube-scheduler                                  ClusterRole/system:kube-scheduler                                                  3h40m
# system:metrics-server                                  ClusterRole/system:metrics-server                                                  3h40m
# system:monitoring                                      ClusterRole/system:monitoring                                                      3h40m
# system:node                                            ClusterRole/system:node                                                            3h40m
# system:node-proxier                                    ClusterRole/system:node-proxier                                                    3h40m
# system:persistent-volume-binding                       ClusterRole/system:persistent-volume-secret-operator                               3h40m
# system:prometheus                                      ClusterRole/system:prometheus                                                      3h38m
# system:public-info-viewer                              ClusterRole/system:public-info-viewer                                              3h40m
# system:service-account-issuer-discovery                ClusterRole/system:service-account-issuer-discovery                                3h40m
# system:volume-scheduler                                ClusterRole/system:volume-scheduler                                                3h40m
```
</details>

## 2. Using Role and RoleBinding to assign roles to users and groups

```powershell
kubectl create namespace my-namespace
# namespace/my-namespace created
```

Create a role for only listing pods

```powershell
kubectl create role pod-reader-role --verb=get --verb=list --verb=watch --resource=pods -n my-namespace -o yaml --dry-run=client > pod-reader-role.yaml

cat pod-reader-role.yaml
# apiVersion: rbac.authorization.k8s.io/v1
# kind: Role
# metadata:
#   creationTimestamp: null
#   name: pod-reader
#   namespace: my-namespace
# rules:
# - apiGroups:
#   - ""
#   resources:
#   - pods
#   verbs:
#   - get
#   - list
#   - watch

kubectl apply -f pod-reader-role.yaml
```

## 3. Create a role binding for user1, user2, and group1 using the pod reader role

```powershell
kubectl create rolebinding user-pod-reader-binding --role=pod-reader-role --user=user1 --user=user2 --group=group1 -n my-namespace -o yaml --dry-run=client > user-pod-reader-binding.yaml

cat user-pod-reader-binding.yaml
# apiVersion: rbac.authorization.k8s.io/v1
# kind: RoleBinding
# metadata:
#   name: user-pod-reader-binding
# roleRef:
#   apiGroup: rbac.authorization.k8s.io
#   kind: Role
#   name: pod-reader
# subjects:
# - apiGroup: rbac.authorization.k8s.io
#   kind: User
#   name: user1
# - apiGroup: rbac.authorization.k8s.io
#   kind: User
#   name: user2
# - apiGroup: rbac.authorization.k8s.io
#   kind: Group
#   name: group1

kubectl apply -f user-pod-reader-binding.yaml
# rolebinding.rbac.authorization.k8s.io/user-pod-reader-binding created
```

Verify the created role and role binding

```powershell
kubectl get role,rolebinding -n my-namespace
# NAME                                             CREATED AT
# role.rbac.authorization.k8s.io/pod-reader-role   2023-01-02T11:00:29Z
# 
# NAME                                                            ROLE                   AGE
# rolebinding.rbac.authorization.k8s.io/user-pod-reader-binding   Role/pod-reader-role   22m
```

## 4. Verify user access using impersonation

Check with the right action, namespace and user

```powershell
kubectl auth can-i get pods --namespace my-namespace --as user1
# yes

kubectl create deployment nginx --image=nginx -n my-namespace --replicas=2 # as myself
# deployment.apps/nginx created

kubectl get pods --namespace my-namespace --as user1
# NAME                    READY   STATUS    RESTARTS   AGE
# nginx-76d6c9b8c-vgbmg   1/1     Running   0          9s
# nginx-76d6c9b8c-wst6z   1/1     Running   0          9s
```

Verify with not allowed user

```powershell
kubectl auth can-i get pods --namespace my-namespace --as user3
# no

kubectl get pods --namespace my-namespace --as user3
# Error from server (Forbidden): pods is forbidden: User "user3" cannot list resource "pods" in API group "" in the namespace "my-namespace"
```

Verify with not allowed resource

```powershell
kubectl auth can-i get secrets --namespace my-namespace --as user1
# no
```

Verify with not allowed namespace
```powershell
kubectl auth can-i get pods --namespace default --as user1
# no
```