# AI UI Application with CI/CD

This repository contains an AI UI application with a CI/CD pipeline set up using GitHub Actions and Kubernetes (Kind).

## Project Structure

*   `app/frontend`: Frontend application (e.g., React, Vue, Angular)
*   `app/backend`: Backend application (e.g., Python FastAPI)
*   `ci-cd/github-actions`: GitHub Actions workflows
*   `ci-cd/kubernetes`: Kubernetes manifests for deployment
*   `ci-cd/scripts`: Helper scripts for CI/CD
*   `docs`: Project documentation

## CI/CD Pipeline

The CI/CD pipeline is configured to:
1.  Build Docker images for both frontend and backend on `push` to `main` branch.
2.  Run tests for the backend.
3.  Push images to GitHub Container Registry (ghcr.io).
4.  Deploy the application to a Kubernetes cluster (Kind for local development).

## Local Development with Kind

1.  **Install Kind**:
    ```bash
    brew install kind
    ```
2.  **Create Kind Cluster**:
    ```bash
    kind create cluster --name ai-ui-cluster --config ./ci-cd/kubernetes/config/kind-config.yaml
    ```
3.  **Build and Load Docker Images (Local)**:
    ```bash
    docker build -t ai-ui-frontend:local ./app/frontend
    docker build -t ai-ui-backend:local ./app/backend
    kind load docker-image ai-ui-frontend:local --name ai-ui-cluster
    kind load docker-image ai-ui-backend:local --name ai-ui-cluster
    ```
4.  **Deploy to Kind Cluster**:
    ```bash
    kubectl apply -f ./ci-cd/kubernetes/deployments/frontend-deployment.yaml
    kubectl apply -f ./ci-cd/kubernetes/services/frontend-service.yaml
    kubectl apply -f ./ci-cd/kubernetes/deployments/backend-deployment.yaml
    kubectl apply -f ./ci-cd/kubernetes/services/backend-service.yaml
    ```
5.  **Access the application**:
    The frontend will be available on `localhost:30080`.
