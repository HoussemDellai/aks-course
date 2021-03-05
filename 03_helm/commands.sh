# Install Helm, guide: https://helm.sh/docs/intro/install/
# Check Helm version
helm version

# Create a sample chart
helm create firstchart

# Check Helm syntax
helm lint firstchart

# Install Helm chart
helm install my-app firstchart

# Install Helm chart and override values
helm install --set image.tag="1.19.0" my-app firstchart

# Install Helm chart and override values.yaml
helm install -f values.yaml my-app firstchart

# Install Helm chart and override values and values.yaml
helm install -f values.yaml --set image.tag="1.19.0" my-app firstchart

# List installed charts
helm list

# Upgrade a chart
helm upgrade --install --set service.type=LoadBalancer my-app firstchart

# Delete a Helm chart
helm uninstall my-app

# Add Helm repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# Install a chart from a repository
helm install my-release bitnami/jenkins