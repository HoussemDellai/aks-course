# 0. Setting up AKS with Calico enabled

# 1. Set up the environment
# 1.1. Create development namespace with labels
kubectl create -f 1-namespace-development.yaml
# or
kubectl create namespace development
kubectl label namespace/development purpose=development

# 1.2. Create an nginx Pod and Service
kubectl run backend --image=nginx --labels app=webapp,role=backend --namespace development --expose --port 80
# or
kubectl create -f 1-pod-svc-nginx-backend.yaml

# 1.3. Create Alpine Pod for testing access to other pods
kubectl run --rm -it --image=alpine network-policy --namespace development
wget -qO- http://backend
# or
kubectl create -f 1-pod-alpine-test.yaml
kubectl exec alpine -n development -- wget -qO- http://backend

# 1.4. Create a Network Policy to deny all connections to backend Pod
kubectl apply -f 1-network-policy-deny-all.yaml

# 1.5. Test access to backend Pod
# We'll reuse the same Aplpine image to run the test:
kubectl run --rm -it --image=alpine network-policy --namespace development
wget -qO- --timeout=2 http://backend
# or
kubectl exec alpine -n development -- wget -qO- --timeout=2 http://backend

# 2. Allow inbound traffic based on pod labels
# 2.1. Update the previous Network Policy to allow traffic from only pods with specific labels
kubectl apply -f 2-network-policy-allow-pod.yaml
# 2.2. Test pod with matching labels
kubectl run --rm -it frontend --image=alpine --labels app=webapp,role=frontend --namespace development
wget -qO- http://backend

# 2.3. Test pod without matching labels
kubectl run --rm -it --image=alpine network-policy --namespace development
wget -qO- --timeout=2 http://backend

# 3. Allow traffic only from pods with matching labels and within specific namespace
# 3.1. Test without policy and pod reaching other namespaces
kubectl create namespace production
kubectl label namespace/production purpose=production
kubectl run --rm -it frontend --image=alpine --labels app=webapp,role=frontend --namespace production
wget -qO- http://backend.development

# 3.2. Create the policy
kubectl apply -f 3-network-policy-allow-pod-namespace.yaml

# 3.3. Test with policy and pod with matching labels and not within specific namespace
kubectl run --rm -it frontend --image=alpine --labels app=webapp,role=frontend --namespace production
wget -qO- --timeout=2 http://backend.development

# 3.4. Test with policy and pod with matching labels and within specific namespace
kubectl run --rm -it frontend --image=alpine --labels app=webapp,role=frontend --namespace development
wget -qO- http://backend

