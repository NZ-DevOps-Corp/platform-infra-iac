# File: infra-repo/scripts/05_deploy_application.sh

#!/bin/bash
# Script to create and sync the final application definition in ArgoCD.

set -euo pipefail

# --- CONFIGURATION (Ensure GITHUB_USERNAME is exported) ---
# Your GitHub username should be exported as an environment variable (GITHUB_USERNAME).
# Replace 'nz-k8s-app-config' with your config repository name if it differs.
APP_CONFIG_REPO_NAME="nz-k8s-app-config"
REPO_URL="https://github.com/${GITHUB_USERNAME}/${APP_CONFIG_REPO_NAME}.git" 
# --- END CONFIGURATION ---

# 1. Check for Required Environment Variables
if [ -z "$GITHUB_USERNAME" ]; then
    echo "ERROR: GITHUB_USERNAME environment variable must be exported before running this script."
    exit 1
fi

# 2. Set ArgoCD CLI Options (Requires port-forward to be running in a separate terminal)
export ARGOCD_OPTS="--insecure --port-forward --port-forward-namespace argocd"

echo "--- 3. Registering Application Configuration Repository (nz-k8s-app-config) ---"
# This registers the new private repository with ArgoCD using the PAT.
argocd repo add "$REPO_URL" \
    --username "$GITHUB_USERNAME" \
    --password "$GITHUB_PAT" \
    --upsert # The --upsert flag updates the repo if it already exists

echo "--- 4. Creating ArgoCD Application Link ---"
# This command tells ArgoCD to monitor your new GitOps repository
argocd app create aks-web-app \
  --repo "$REPO_URL" \
  --path . \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy automated

echo "--- 4. Forcing Initial Application Sync ---"
# This command forces ArgoCD to immediately pull the YAML and deploy the pods to AKS
argocd app sync aks-web-app

echo " "
echo "✅ Application Deployment Initiated!"
echo "   - Status can be checked via CLI: argocd app get aks-web-app"
echo "   - Or in the ArgoCD UI: https://localhost:8080"
echo " "