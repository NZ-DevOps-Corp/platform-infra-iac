# File: scripts/03_install_argocd.sh

#!/bin/bash
# Script to connect to the new AKS cluster and install ArgoCD (GitOps Engine)

set -euo pipefail

# --- Configuration Variables (UPDATED TO REFLECT MODULAR NAMING) ---
# NOTE: Update these variables to match the values in your envs/dev/variables.tf
PROJECT_NAME="aksgitops"
ENVIRONMENT="dev" 

# The Resource Group holding the VNet/Subnets (defined in envs/dev/main.tf)
RESOURCE_GROUP="rg-${PROJECT_NAME}-net-${ENVIRONMENT}" 
# The AKS Cluster Name (defined in modules/aks-cluster/main.tf)
AKS_NAME="aks-${PROJECT_NAME}-${ENVIRONMENT}" 

echo "--- 1. Retrieving AKS Credentials and merging into kubeconfig ---"
# Downloads the necessary certificates and connection details for kubectl
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_NAME" --overwrite-existing

echo "--- 2. Verifying Kubernetes Node Status ---"
# Confirms kubectl can communicate with the cluster and nodes are Ready
kubectl get nodes

echo "--- 3. Installing ArgoCD Components ---"
# Create namespace and apply the official ArgoCD manifest
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "--- 4. Retrieving Initial ArgoCD Admin Password ---"
# Retrieves the password from the Kubernetes Secret and decodes it
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo " "
echo "✅ ArgoCD Installation Complete!"
echo "   - The initial Admin Password is: ${ARGOCD_PASSWORD}"
echo "   - To access the Web UI, run the port-forward command in a NEW terminal:"
echo "     kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "   - Then open https://localhost:8080 in your browser. (Username: admin)"
echo " "