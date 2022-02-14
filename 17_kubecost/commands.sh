 $ kubectl create namespace kubecost
namespace/kubecost created
 $
 $ helm repo add kubecost https://kubecost.github.io/cost-analyzer/
"kubecost" already exists with the same configuration, skipping
 $
 $ helm install kubecost kubecost/cost-analyzer --namespace kubecost --set kubecostToken="aG91c3NlbS5kZWxsYWlAZ21haWwuY29txm343yadf98"