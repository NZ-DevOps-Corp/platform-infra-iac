# File: scripts/05_deploy_application.sh

#!/bin/bash
# Script to create and sync the final application definition in ArgoCD.

set -euo pipefail

# --- CONFIGURATION (Ensure GITHUB_USERNAME is exported) ---
# Replace 'app-config-repo' with the name of the repository that holds your application YAMLs.
APP_CONFIG_REPO_NAME="app-config-repo"
# The full URL to your application configuration repository
REPO_URL="https://github.com/${GITHUB_USERNAME}/${APP_CONFIG_REPO_NAME}.git" 
# --- END CONFIGURATION ---

# 1. Check for Required Environment Variables
if [ -z "$GITHUB_USERNAME" ] || [ -z "$GITHUB_PAT" ]; then
    echo "ERROR: GITHUB_USERNAME and GITHUB_PAT environment variables must be exported before running this script."
    exit 1
fi

# 2. Set ArgoCD CLI Options (Requires port-forward to be running in a separate terminal)
# NOTE: You must run 'kubectl port-forward svc/argocd-server -n argocd 8080:443' separately.
export ARGOCD_OPTS="--insecure" 

echo "--- 3. Registering Application Configuration Repository (${APP_CONFIG_REPO_NAME}) ---"
# This registers the new private repository with ArgoCD using the PAT.
argocd repo add "$REPO_URL" \
    --username "$GITHUB_USERNAME" \
    --password "$GITHUB_PAT" \
    --upsert 

echo "--- 4. Creating ArgoCD Application Link ---"
# This command tells ArgoCD to monitor your new GitOps repository
argocd app create aks-web-app \
  --repo "$REPO_URL" \
  --path . \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy automated

echo "--- 5. Forcing Initial Application Sync ---"
# This command forces ArgoCD to immediately pull the YAML and deploy the pods to AKS
argocd app sync aks-web-app

echo " "
echo "✅ Application Deployment Initiated!"
echo "   - Status can be checked via CLI: argocd app get aks-web-app"
echo " "