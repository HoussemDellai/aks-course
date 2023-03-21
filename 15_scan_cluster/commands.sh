# Scan cluster configuration using Kube-Bench
# src: https://github.com/aquasecurity/kube-bench

          kubectl cluster-info
          # Deploy job.yaml to scan Kubernetes config and job-aks.yaml to scan specific AKS config
          kubectl apply -f https://raw.githubusercontent.com/aquasecurity/kube-bench/main/job.yaml
          # Pod logs outputs Kubernetes scan results and Job outputs AKS specific results
          POD=$(kubectl get pods --selector app=kube-bench -o name)
          kubectl logs $POD
          kubectl delete -f https://raw.githubusercontent.com/aquasecurity/kube-bench/main/job.yaml

          kubectl apply -f https://raw.githubusercontent.com/aquasecurity/kube-bench/main/job-aks.yaml
          
          JOB=(kubectl get jobs --selector job-name=kube-bench -o name)
          kubectl logs $JOB
          # TODO upload the scan results
          kubectl delete -f https://raw.githubusercontent.com/aquasecurity/kube-bench/main/job-aks.yaml