# Moshi Helm Chart

This Helm chart deploys Moshi, a speech-text foundation model for real-time dialogue, on Kubernetes (K3s).

## Prerequisites

- Kubernetes cluster (K3s recommended) with GPU support
- NVIDIA GPU Operator installed (for GPU nodes)
- Helm 3.x
- Traefik or NGINX ingress controller
- Longhorn or other storage class for model persistence

## Installation

### 1. Add NVIDIA GPU Operator (if not already installed)

```bash
helm repo add nvidia https://nvidia.github.io/gpu-operator
helm repo update
helm install gpu-operator nvidia/gpu-operator --namespace gpu-operator --create-namespace
```

### 2. Install Moshi

```bash
cd helm/moshi

# Update dependencies
helm dependency update

# Install with default values
helm install moshi . --namespace moshi --create-namespace

# Or with custom values
helm install moshi . -f values-production.yaml --namespace moshi --create-namespace
```

### 3. Access the Application

```bash
# Port-forward to access locally
kubectl port-forward svc/moshi-webui 8080:80 -n moshi

# Open http://localhost:8080
```

## Configuration

### GPU Support

Enable GPU in `values.yaml`:
```yaml
backend:
  gpu:
    enabled: true
    count: 1
    type: nvidia.com/gpu
```

### Model Selection

Choose which model to download:
```yaml
model:
  hfRepo: "kyutai/moshiko-pytorch-bf16"
  # or "kyutai/moshika-pytorch-bf16"
```

### Ingress Configuration

Configure ingress for external access:
```yaml
webui:
  ingress:
    enabled: true
    className: "traefik"
    hosts:
      - host: moshi.yourdomain.com
```

### Storage

Configure model storage:
```yaml
model:
  storage:
    size: 50Gi
    storageClass: "longhorn"
```

## Uninstallation

```bash
helm uninstall moshi -n moshi
kubectl delete namespace moshi
```

## Architecture

The deployment consists of:
1. **Model Download Job** - Downloads models from HuggingFace
2. **Backend Deployment** - Moshi inference server with GPU
3. **WebUI Deployment** - React frontend
4. **Services** - Kubernetes services for communication
5. **Ingress** - External access configuration

## Troubleshooting

### Check pod status
```bash
kubectl get pods -n moshi
```

### Check logs
```bash
kubectl logs -f deployment/moshi-backend -n moshi
kubectl logs -f deployment/moshi-webui -n moshi
```

### Check model download
```bash
kubectl logs job/moshi-model-download -n moshi
```

### GPU not available
Ensure NVIDIA GPU Operator is installed and nodes are labeled:
```bash
kubectl describe nodes | grep nvidia.com/gpu
```
