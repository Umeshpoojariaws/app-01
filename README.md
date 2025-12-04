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
    The frontend will be available on `http://localhost:30080`.

## Pulling Images from GitHub Container Registry (Advanced)

If you wish for your Kind cluster to pull images directly from GitHub Container Registry (ghcr.io) rather than loading them locally, you will need to configure Kubernetes `imagePullSecrets`. This is useful if you intend to modify your Kubernetes deployment manifests to directly reference images from `ghcr.io` (e.g., `ghcr.io/umeshpoojariaws/ai-ui-frontend:sha-of-commit`).

1.  **Generate a GitHub Personal Access Token (PAT)**:
    *   Go to your GitHub settings: `Settings` > `Developer settings` > `Personal access tokens` > `Tokens (classic)`.
    *   Click `Generate new token` (classic).
    *   Give it a descriptive name (e.g., `k8s-image-pull`).
    *   Set an expiration.
    *   Crucially, grant it the `packages:read` scope.
    *   Generate the token and **copy it immediately** as you won't be able to see it again.

2.  **Create Kubernetes `imagePullSecret`**:
    Replace `<YOUR_GITHUB_USERNAME>` with your GitHub username and `<YOUR_PAT>` with the token you generated.
    ```bash
    kubectl create secret docker-registry ghcr-login-secret \
      --namespace default \
      --docker-server=ghcr.io \
      --docker-username=<YOUR_GITHUB_USERNAME> \
      --docker-password=<YOUR_PAT> \
      --docker-email=<YOUR_GITHUB_EMAIL>
    ```

3.  **Update Deployment Manifests (Optional, if using ghcr.io images directly)**:
    Modify your deployment manifests (e.g., `frontend-deployment.yaml`, `backend-deployment.yaml`) to reference the `ghcr.io` images (e.g., `image: ghcr.io/<YOUR_GITHUB_USERNAME>/ai-ui-frontend:<TAG>`) and include the `imagePullSecrets` in the pod spec:
    ```yaml
    # Example for frontend-deployment.yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: ai-ui-frontend
      # ...
    spec:
      template:
        spec:
          containers:
          - name: ai-ui-frontend
            image: ghcr.io/<YOUR_GITHUB_USERNAME>/ai-ui-frontend:<TAG_FROM_GH_ACTIONS> # e.g., use ${{ github.sha }} tag from CI
            # ...
          imagePullSecrets:
          - name: ghcr-login-secret
    ```
    Remember to replace `<TAG_FROM_GH_ACTIONS>` with the actual tag (e.g., `latest` or a specific commit SHA) that your GitHub Actions workflow pushes to `ghcr.io`.
