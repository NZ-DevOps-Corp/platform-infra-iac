#!/bin/bash
# File: scripts/04_configure_gitops.sh
# Purpose: Configure ArgoCD with the secure repository and change the initial admin password.

set -euo pipefail

# --- CONFIGURATION (UPDATE THESE VALUES) ---
# This is the URL of your infra-repo on GitHub (The source for ArgoCD's configuration)
REPO_URL="https://github.com/NZ-DevOps-Corp/platform-infra-iac.git" 
# --- END CONFIGURATION ---

# 1. Check for Required Environment Variables
if [ -z "$GITHUB_USERNAME" ] || [ -z "$GITHUB_PAT" ]; then
    echo "ERROR: GITHUB_USERNAME and GITHUB_PAT environment variables must be exported for repository access."
    exit 1
fi
if [ -z "$ARGOCD_ADMIN_PASSWORD" ]; then
    echo "ERROR: ARGOCD_ADMIN_PASSWORD environment variable must be exported with your desired new admin password."
    exit 1
fi

# 2. Install ArgoCD CLI (Check if installed)
echo "--- 1. Checking ArgoCD CLI installation ---"
if ! command -v argocd &> /dev/null
then
    echo "ERROR: argocd CLI not found. Please install it (e.g., using 'sudo snap install argocd --classic') and re-run."
    exit 1
fi

# 3. Login to ArgoCD using the initial password
echo "--- 2. Logging into ArgoCD with initial secret password ---"
# Retrieve the initial password from the Kubernetes secret.
INITIAL_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Set ARGOCD_OPTS for connection configuration (assumes port-forward is NOT running yet)
export ARGOCD_OPTS="--insecure --port-forward --port-forward-namespace argocd"

argocd login localhost:8080 --username admin --password "$INITIAL_PASSWORD"

# 4. Change the Admin Password (CRITICAL SECURITY STEP)
echo "--- 3. Changing initial Admin Password for security ---"
# Uses the password passed via the secure environment variable
argocd account update-password \
    --current-password "$INITIAL_PASSWORD" \
    --new-password "$ARGOCD_ADMIN_PASSWORD"

# 5. Cleanup: Delete the initial password Secret
echo "--- 4. Deleting initial secret (argocd-initial-admin-secret) ---"
kubectl delete secret argocd-initial-admin-secret -n argocd

# 6. Register the GitHub Repository (The Source of Truth)
echo "--- 5. Registering GitHub Repository with ArgoCD ---"
# Use the environment variables for secure authentication.
argocd repo add "$REPO_URL" \
    --username "$GITHUB_USERNAME" \
    --password "$GITHUB_PAT"

echo " "
echo "✅ GitOps Configuration Complete!"
echo "    - New ArgoCD Admin Password is set."
echo "    - Your repository is registered."
echo " "