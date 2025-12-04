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

The CI/CD pipeline, configured in `.github/workflows/build-test-deploy.yml`, is designed for a hybrid approach:

1.  **Continuous Integration (CI) on GitHub Actions**:
    *   Builds Docker images for both frontend and backend on `push` to `main` branch (or `pull_request`).
    *   Runs tests for the backend.
    *   Pushes tagged images to GitHub Container Registry (ghcr.io) using a `GHCR_PAT` secret.

2.  **Continuous Deployment (CD) to Local Kind Cluster**: This is a manual step you execute on your local machine, pulling images from `ghcr.io` and applying Kubernetes manifests.

## GitHub Personal Access Tokens (PATs) Configuration

GitHub Personal Access Tokens (PATs) are essential for authenticating with GitHub services, including pushing and pulling Docker images from GitHub Container Registry (ghcr.io).

1.  **Generate a GitHub Personal Access Token (PAT)**:
    *   Go to your GitHub settings: `Settings` > `Developer settings` > `Personal access tokens` > `Tokens (classic)`.
    *   Click `Generate new token` (classic).
    *   Give it a descriptive name (e.g., `CI/CD-PAT`).
    *   Set an expiration.
    *   Crucially, grant the following scopes:
        *   For **pushing images from GitHub Actions to GHCR**: `write:packages` and `read:packages` (or `repo` for full repository access).
        *   For **pulling images into Kubernetes from GHCR**: `read:packages`.
    *   Generate the token and **copy it immediately** as you won't be able to see it again.

2.  **Configure PAT for GitHub Actions (`GHCR_PAT` Secret)**:
    *   This PAT is used by your CI workflow to push images to `ghcr.io`.
    *   Go to your GitHub repository: `Settings` > `Secrets and variables` > `Actions` > `Repository secrets`.
    *   Click `New repository secret`.
    *   Name it `GHCR_PAT`.
    *   Paste the PAT you generated (with `write:packages` scope) as its value.

3.  **Create Kubernetes `imagePullSecret` (`ghcr-login-secret`)**:
    *   This secret allows your Kind cluster to pull images from `ghcr.io`.
    *   Replace `<YOUR_GITHUB_USERNAME>` with your GitHub username, `<YOUR_PAT_WITH_READ_PACKAGES>` with a PAT (from step 1, with `read:packages` scope), and `<YOUR_GITHUB_EMAIL>` with your GitHub email.
    *   Run this command on your local machine (after your Kind cluster is running):
    ```bash
    kubectl create secret docker-registry ghcr-login-secret \
      --namespace default \
      --docker-server=ghcr.io \
      --docker-username=<YOUR_GITHUB_USERNAME> \
      --docker-password=<YOUR_PAT_WITH_READ_PACKAGES> \
      --docker-email=<YOUR_GITHUB_EMAIL>
    ```

## Local Development with Kind

1.  **Install Kind**:
    ```bash
    brew install kind
    ```
2.  **Create Kind Cluster**:
    ```bash
    kind create cluster --name ai-ui-cluster --config ./ci-cd/kubernetes/config/kind-config.yaml
    ```
3.  **Ensure ImagePullSecret is Created**:
    Before deploying, make sure you have created the `ghcr-login-secret` in your Kind cluster as described in the "GitHub Personal Access Tokens (PATs) Configuration" section above.

4.  **Deploy to Kind Cluster**:
    For local deployment, you will typically deploy images that were built and pushed by your CI pipeline to `ghcr.io`. Your deployment manifests need to specify these images and use the `imagePullSecrets`.

    First, update your deployment manifests to reference the images from `ghcr.io` and include the `imagePullSecrets`. Example modification for `frontend-deployment.yaml`:
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
            image: ghcr.io/umeshpoojariaws/ai-ui-frontend:latest # Or use a specific ${{ github.sha }} tag
            ports:
            - containerPort: 3000
          imagePullSecrets:
          - name: ghcr-login-secret # Reference the Kubernetes secret
    ```
    You would apply similar changes to `backend-deployment.yaml`.

    After updating the YAMLs (and ensuring new images are available in ghcr.io from your CI pipeline, or pushed locally with the `:latest` tag), apply them:
    ```bash
    kubectl apply -f ./ci-cd/kubernetes/deployments/frontend-deployment.yaml
    kubectl apply -f ./ci-cd/kubernetes/services/frontend-service.yaml
    kubectl apply -f ./ci-cd/kubernetes/deployments/backend-deployment.yaml
    kubectl apply -f ./ci-cd/kubernetes/services/backend-service.yaml
    ```

5.  **Access the application**:
    The frontend will be available on `http://localhost:30080`.
