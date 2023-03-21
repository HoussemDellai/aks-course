# Creating primary and replicas databases using Statfulset and MySQL

# Introduction

# This lab will create a StatfulSet for MySQL database. 
# We will have one primary instance for read/write and many replicas instances for read-only.
# Data is always inserted into primary database then replicated and synchronized using [Percona XtraBackup] (https://github.com/percona/percona-xtrabackup).

# 0. Setup demo environment
# 1. Deploy statefulset, service and configmap
# 2. Insert data into th primary mysql database
# 4. Read data from a specific replica
# 5. Read data from another specific replica
# 6. Scaling the number of replicas
# 7. Verify database is replicated into the new replicas
# 8. Scaling back down the StatefulSet
# 9. deleting the unneeded PVs

# 0. Setup demo environment

# Variables
$AKS_RG="rg-aks-az"
$AKS_NAME="aks-cluster"

# Create and connect to AKS cluster
az group create --name $AKS_RG --location westeurope

az aks create --name $AKS_NAME `
              --resource-group $AKS_RG `
              --node-count 3 `
              --zones 1 2 3 

az aks get-credentials -n $AKS_NAME -g $AKS_RG --overwrite-existing

kubectl get nodes

# 1. Deploy statefulset, service and configmap

kubectl apply -f .
# configmap/mysql created
# service/mysql created
# service/mysql-read created
# statefulset.apps/mysql created
# storageclass.storage.k8s.io/managed-csi-zrs created

kubectl get sts,pod,svc,pv,pvc
# NAME                     READY   AGE
# statefulset.apps/mysql   3/3     4m7s

# NAME          READY   STATUS    RESTARTS   AGE
# pod/mysql-0   2/2     Running   0          4m7s
# pod/mysql-1   2/2     Running   0          3m14s
# pod/mysql-2   2/2     Running   0          2m19s

# NAME                 TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
# service/kubernetes   ClusterIP   10.0.0.1      <none>        443/TCP    88m
# service/mysql        ClusterIP   None          <none>        3306/TCP   4m7s
# service/mysql-read   ClusterIP   10.0.99.145   <none>        3306/TCP   4m7s

# NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                  STORAGECLASS   REASON   AGE
# persistentvolume/pvc-276393bc-81a5-42e6-ab8e-3e29a3385f7c   10Gi       RWO            Delete           Bound    default/data-mysql-0   managed-csi             4m4s
# persistentvolume/pvc-e55cdf98-a35e-4067-8d9f-b630c10bbfbd   10Gi       RWO            Delete           Bound    default/data-mysql-1   managed-csi             3m12s
# persistentvolume/pvc-ea2055ff-5b7b-4d8d-9eae-e61450c9b5ce   10Gi       RWO            Delete           Bound    default/data-mysql-2   managed-csi             2m17s

# NAME                                 STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# persistentvolumeclaim/data-mysql-0   Bound    pvc-276393bc-81a5-42e6-ab8e-3e29a3385f7c   10Gi       RWO            managed-csi    4m7s
# persistentvolumeclaim/data-mysql-1   Bound    pvc-e55cdf98-a35e-4067-8d9f-b630c10bbfbd   10Gi       RWO            managed-csi    3m14s
# persistentvolumeclaim/data-mysql-2   Bound    pvc-ea2055ff-5b7b-4d8d-9eae-e61450c9b5ce   10Gi       RWO            managed-csi    2m19s

# 2. Insert data into th primary mysql database

# You can send test queries to the primary MySQL server (hostname mysql-0.mysql) 
# by running a temporary container with the mysql:5.7 image and running the mysql client binary.
kubectl run mysql-client --image=mysql:5.7 -i --rm --restart=Never -- `
  mysql -h mysql-0.mysql -e "
    CREATE DATABASE test; 
    CREATE TABLE test.messages (message VARCHAR(250)); 
    INSERT INTO test.messages VALUES ('hello');
"
# pod "mysql-client" deleted

# Watch what will happen now.

# Cloning existing data

# when a new Pod joins the set as a replica, it must assume the primary MySQL server might already have data on it.
# The second init container, named clone-mysql, performs a clone operation on a replica Pod the first time 
# it starts up on an empty PersistentVolume. That means it copies all existing data from another running Pod, 
# so its local state is consistent enough to begin replicating from the primary server.
# MySQL itself does not provide a mechanism to do this, 
# so the example uses a popular open-source tool called Percona XtraBackup. 
# During the clone, the source MySQL server might suffer reduced performance. 
# To minimize impact on the primary MySQL server, the script instructs each Pod to clone from the Pod whose ordinal index is one lower.
# This works because the StatefulSet controller always ensures Pod N is Ready before starting Pod N+1.

# Starting replication

# After the init containers complete successfully, the regular containers run. 
# The MySQL Pods consist of a mysql container that runs the actual mysqld server, 
# and an xtrabackup container that acts as a sidecar.
# The xtrabackup sidecar looks at the cloned data files and determines if it's necessary to initialize MySQL replication on the replica. 
# If so, it waits for mysqld to be ready and then executes commands with replication parameters extracted from the XtraBackup clone files.
# Replicas look for the primary server at its stable DNS name (mysql-0.mysql), 
# they automatically find the primary server even if it gets a new Pod IP due to being rescheduled.

# 3. Query database using the exposed service for read-only

# Test hostname mysql-read to send test queries to any server that reports being Ready:

kubectl run mysql-client --image=mysql:5.7 -i -t --rm --restart=Never -- `
  mysql -h mysql-read -e "
    SELECT * FROM test.messages
"
# +---------+
# | message |
# +---------+
# | hello   |
# +---------+
# pod "mysql-client" deleted

# 4. Read data from a specific replica

kubectl run mysql-client --image=mysql:5.7 -i -t --rm --restart=Never -- `
  mysql -h mysql-1.mysql -e "SELECT * FROM test.messages"
#   +---------+
#   | message |
#   +---------+
#   | hello   |
#   +---------+
#   pod "mysql-client" deleted

# 5. Read data from another specific replica

kubectl run mysql-client --image=mysql:5.7 -i -t --rm --restart=Never -- `
  mysql -h mysql-2.mysql -e "SELECT * FROM test.messages"
#   +---------+
#   | message |
#   +---------+
#   | hello   |
#   +---------+
#   pod "mysql-client" deleted

# To demonstrate that the mysql-read Service distributes connections across servers, you can run SELECT @@server_id in a loop:

kubectl run mysql-client-loop --image=mysql:5.7 -i -t --rm --restart=Never -- `
  bash -ic "while sleep 1; do mysql -h mysql-read -e 'SELECT @@server_id,NOW()'; done"
#   If you don't see a command prompt, try pressing enter.
# #   +-------------+---------------------+
# #   | @@server_id | NOW()               |
# #   +-------------+---------------------+
# #   |         102 | 2022-12-21 14:34:09 |
# #   +-------------+---------------------+
# #   +-------------+---------------------+
# #   | @@server_id | NOW()               |
# #   +-------------+---------------------+
# #   |         100 | 2022-12-21 14:34:10 |
# #   +-------------+---------------------+
# #   +-------------+---------------------+
# #   | @@server_id | NOW()               |
# #   +-------------+---------------------+
# #   |         101 | 2022-12-21 14:34:11 |
# #   +-------------+---------------------+

# 6. Scaling the number of replicas

# When you use MySQL replication, you can scale your read query capacity by adding replicas. 
# For a StatefulSet, you can achieve this with a single command:

kubectl scale statefulset mysql --replicas=5
# statefulset.apps/mysql scaled

kubectl get pods -l app=mysql --watch
# NAME      READY   STATUS    RESTARTS   AGE
# mysql-0   2/2     Running   0          3h32m
# mysql-1   2/2     Running   0          3h31m
# mysql-2   2/2     Running   0          8m37s
# mysql-3   0/2     Pending   0          1s
# mysql-3   0/2     Pending   0          3s
# mysql-3   0/2     Init:0/2   0          3s
# mysql-3   0/2     Init:1/2   0          15s
# mysql-3   0/2     Init:1/2   0          16s
# mysql-3   0/2     PodInitializing   0          24s
# mysql-3   1/2     Running           0          25s
# mysql-3   2/2     Running           0          31s
# mysql-4   0/2     Pending           0          0s
# mysql-4   0/2     Pending           0          3s
# mysql-4   0/2     Init:0/2          0          3s
# mysql-4   0/2     Init:1/2          0          16s
# mysql-4   0/2     Init:1/2          0          17s
# mysql-4   0/2     PodInitializing   0          24s
# mysql-4   1/2     Running           0          25s
# mysql-4   2/2     Running           0          30s

# 7. Verify database is replicated into the new replicas

# Verify that these new servers have the data you added before they existed:

kubectl run mysql-client --image=mysql:5.7 -i -t --rm --restart=Never -- `
  mysql -h mysql-3.mysql -e "SELECT * FROM test.messages"
# +---------+
# | message |
# +---------+
# | hello   |
# +---------+
# pod "mysql-client" deleted

kubectl run mysql-client --image=mysql:5.7 -i -t --rm --restart=Never -- `
  mysql -h mysql-4.mysql -e "SELECT * FROM test.messages"
# +---------+
# | message |
# +---------+
# | hello   |
# +---------+
# pod "mysql-client" deleted

# 8. Scaling back down the StatefulSet

kubectl scale statefulset mysql --replicas=3

# Although scaling up creates new PersistentVolumeClaims automatically, scaling down does not automatically delete these PVCs.
# This gives you the choice to keep those initialized PVCs around to make scaling back up quicker, 
# or to extract data before deleting them.

kubectl get pvc -l app=mysql
# NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# data-mysql-0   Bound    pvc-dac5ffbe-bddf-4698-849a-1ef74bc9d8b8   10Gi       RWO            managed-csi    3h36m
# data-mysql-1   Bound    pvc-bb3c6e54-e81e-42f9-afb2-33d0f38ecd11   10Gi       RWO            managed-csi    3h35m
# data-mysql-2   Bound    pvc-ef996d92-f734-4f5a-ac1c-7d02cb7b627e   10Gi       RWO            managed-csi    3h35m
# data-mysql-3   Bound    pvc-496e2611-2523-4b86-8d2c-bc013ce34234   10Gi       RWO            managed-csi    3m53s
# data-mysql-4   Bound    pvc-d9fe412f-0af7-4622-a398-2fd0d52b8db7   10Gi       RWO            managed-csi    3m22s

# 9. deleting the unneeded PVs

kubectl delete pvc data-mysql-3
kubectl delete pvc data-mysql-4

kubectl get pvc -l app=mysql
# NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
# data-mysql-0   Bound    pvc-dac5ffbe-bddf-4698-849a-1ef74bc9d8b8   10Gi       RWO            managed-csi    3h36m
# data-mysql-1   Bound    pvc-bb3c6e54-e81e-42f9-afb2-33d0f38ecd11   10Gi       RWO            managed-csi    3h35m
# data-mysql-2   Bound    pvc-ef996d92-f734-4f5a-ac1c-7d02cb7b627e   10Gi       RWO            managed-csi    3h35m

# resources: https://kubernetes.io/docs/tasks/run-application/run-replicated-stateful-application/