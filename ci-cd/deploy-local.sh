#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.

# Get the directory where the script is located
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

KIND_CLUSTER_NAME="ai-ui-cluster"
# Paths relative to SCRIPT_DIR (which is ../../app-01/ci-cd/)
KUBERNETES_DIR="${SCRIPT_DIR}/kubernetes"
DEPLOYMENTS_DIR="${KUBERNETES_DIR}/deployments"
SERVICES_DIR="${KUBERNETES_DIR}/services"
CONFIG_DIR="${KUBERNETES_DIR}/config"

# Argument for the commit SHA
COMMIT_SHA=$1
if [ -z "$COMMIT_SHA" ]; then
  echo "Usage: $0 <COMMIT_SHA>"
  echo "Please provide the GitHub commit SHA of the image to deploy."
  exit 1
fi

echo "--- Setting up local Kind cluster for CD ---"

# 1. Create Kind cluster if it doesn't exist
if ! kind get clusters | grep -q "$KIND_CLUSTER_NAME"; then
  echo "Kind cluster '$KIND_CLUSTER_NAME' not found. Creating it..."
  kind create cluster --name "$KIND_CLUSTER_NAME" --config "${CONFIG_DIR}/kind-config.yaml"
  echo "Kind cluster '$KIND_CLUSTER_NAME' created successfully."
else
  echo "Kind cluster '$KIND_CLUSTER_NAME' already exists."
fi

# Ensure kubectl context is set to the Kind cluster
echo "Setting kubectl context to kind-$KIND_CLUSTER_NAME..."
kubectl cluster-info --context "kind-$KIND_CLUSTER_NAME"

# Create a temporary directory for deployment files
TEMP_DEPLOY_DIR=$(mktemp -d -t kind-deploy-XXXXXXXXXX)
echo "Created temporary directory: ${TEMP_DEPLOY_DIR}"

# Ensure the temporary directory is removed on exit
trap "echo 'Cleaning up temporary directory: ${TEMP_DEPLOY_DIR}'; rm -rf ${TEMP_DEPLOY_DIR}" EXIT

# 2. Create temporary deployment files with the specified COMMIT_SHA and imagePullPolicy
echo "Creating temporary deployment files for COMMIT_SHA: ${COMMIT_SHA} in ${TEMP_DEPLOY_DIR}..."

# Frontend Deployment modification:
# 1. Replace image tag from :latest to :${COMMIT_SHA}
# 2. Insert imagePullPolicy: Always on a new line, correctly indented, right after the image line.
sed -E "s|(image: ghcr.io/umeshpoojariaws/ai-ui-frontend):latest|\1:${COMMIT_SHA}\n        imagePullPolicy: Always|g" \
    "${DEPLOYMENTS_DIR}/frontend-deployment.yaml" > "${TEMP_DEPLOY_DIR}/frontend-deployment.yaml"

# Backend Deployment modification:
# 1. Replace image tag from :latest to :${COMMIT_SHA}
# 2. Insert imagePullPolicy: Always on a new line, correctly indented, right after the image line.
sed -E "s|(image: ghcr.io/umeshpoojariaws/ai-ui-backend):latest|\1:${COMMIT_SHA}\n        imagePullPolicy: Always|g" \
    "${DEPLOYMENTS_DIR}/backend-deployment.yaml" > "${TEMP_DEPLOY_DIR}/backend-deployment.yaml"

# Copy service manifests (no changes needed for services)
cp "${SERVICES_DIR}/frontend-service.yaml" "${TEMP_DEPLOY_DIR}/frontend-service.yaml"
cp "${SERVICES_DIR}/backend-service.yaml" "${TEMP_DEPLOY_DIR}/backend-service.yaml"


# 3. Apply Kubernetes manifests from the temporary directory
echo "Applying Kubernetes manifests from ${TEMP_DEPLOY_DIR} to Kind cluster, pulling images with SHA tag..."
kubectl apply -f "${TEMP_DEPLOY_DIR}/frontend-deployment.yaml"
kubectl apply -f "${TEMP_DEPLOY_DIR}/backend-deployment.yaml"
kubectl apply -f "${TEMP_DEPLOY_DIR}/frontend-service.yaml"
kubectl apply -f "${TEMP_DEPLOY_DIR}/backend-service.yaml"
echo "Kubernetes manifests applied successfully."

echo "--- Local CD setup complete! ---"
echo "To deploy, run the script with the commit SHA: bash ./ci-cd/deploy-local.sh <YOUR_COMMIT_SHA>"
echo "Wait for pods to be ready (run: kubectl get pods -w)"
echo "Access Frontend at: http://localhost:30080"
