#!/usr/bin/env bash
# File: scripts/01_provision_state_backend.sh
# Purpose: Manually provisions the secure Azure Storage Account for Terraform Remote State Backend.

set -euo pipefail

# --- CONFIGURATION VARIABLES ---
# CRITICAL: These must match the values hardcoded in envs/dev/main.tf and envs/prod/main.tf
# ⚠️ ACTION: Change STATE_SA_NAME to be globally unique before running (e.g., add initials/date)
STATE_RG_NAME="rg-tfstate-storage"
STATE_SA_NAME="tfstateprodaks99"
STATE_CONTAINER_NAME="tfstate"
LOCATION="eastus" # Use your desired primary region

echo "--- Starting Provisioning of Terraform State Backend ---"

# 1. Check Azure Login
if ! az account show 1> /dev/null; then
    echo "ERROR: You must run 'az login' before executing this script."
    exit 1
fi

# 2. Create Resource Group for the Backend
echo "Creating state resource group '$STATE_RG_NAME' in '$LOCATION'..."
az group create --name "$STATE_RG_NAME" --location "$LOCATION" --output none

# 3. Create Secure Storage Account
echo "Creating secure storage account '$STATE_SA_NAME'..."
az storage account create \
    --name "$STATE_SA_NAME" \
    --resource-group "$STATE_RG_NAME" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --encryption-services blob \
    --allow-blob-public-access false \
    --min-tls-version TLS1_2 \
    --kind StorageV2 \
    --output none

# 4. Create Container
echo "Creating state container '$STATE_CONTAINER_NAME'..."
az storage container create \
    --name "$STATE_CONTAINER_NAME" \
    --account-name "$STATE_SA_NAME" \
    --resource-group "$STATE_RG_NAME" \
    --output none

echo " "
echo "========================================================================="
echo "✅ REMOTE STATE BACKEND PROVISIONED SUCCESSFULLY!"
echo "   Resource Group: ${STATE_RG_NAME}"
echo "   Storage Account: ${STATE_SA_NAME}"
echo "   Container: ${STATE_CONTAINER_NAME}"
echo "========================================================================="
echo " "