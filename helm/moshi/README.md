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

## Test Environment

Deploy a lightweight test environment using Q8 quantized model (<12GB VRAM):

```bash
helm install moshi-test . -f values-test.yaml --namespace moshi-test --create-namespace
```

The test environment uses:
- **Model**: `kyutai/moshika-pytorch-q8` (Q8 quantized, ~12GB VRAM)
- **Resources**: Reduced limits (12Gi memory, 4 CPU cores)
- **Storage**: 20Gi for model cache
- **Ingress**: `test.moshi.homelab`

### Alternative Model

To use the male voice variant:
```bash
helm install moshi-test . -f values-test.yaml \
  --set model.hfRepo=kyutai/moshiko-pytorch-q8 \
  --namespace moshi-test --create-namespace
```

## GPU Time-Slicing

Share a single GPU across multiple pods using NVIDIA time-slicing.

### Prerequisites (Cluster-Level Setup)

1. **NVIDIA Device Plugin Configuration** (managed by cluster admin):
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nvidia-device-plugin-config
  namespace: nvidia-device-plugin
data:
  config: |
    {
      "sharing": {
        "timeSlicing": {
          "renameByDefault": false,
          "failRequestsGreaterThanOne": false
        }
      }
    }
```

2. Apply the configuration and restart the GPU operator

### Enable Time-Slicing in Helm

```yaml
backend:
  gpu:
    enabled: true
    count: 1
    shared: true  # Uses nvidia.com/gpu.shared resource type
```

**Note**: Time-slicing requires cluster-level setup. Pods will fail to schedule if the cluster doesn't have the shared GPU resource configured.

## Observability Stack

Deploy optional Prometheus and Grafana for monitoring Moshi metrics.

### Enable Observability

```bash
helm install moshi-test . -f values-test.yaml \
  --set observability.enabled=true \
  --set observability.grafana.adminPassword=secure-password \
  --namespace moshi-test --create-namespace
```

### Access Grafana

- **URL**: http://grafana.moshi.homelab
- **Default Credentials**: admin / changeme (configure in values)

### Available Dashboards

1. **Moshi Overview**: Token throughput, audio frames, latency
2. **GPU Utilization**: Memory usage, compute utilization
3. **Resource Usage**: CPU and memory over time

### Metrics Collected

The observability stack parses Moshi backend logs to expose:

| Metric | Type | Description |
|--------|------|-------------|
| `moshi_text_tokens_total` | Counter | Total text tokens generated |
| `moshi_tokens_per_sec` | Gauge | Token throughput |
| `moshi_audio_frames_total` | Counter | Audio frames processed |
| `moshi_inference_latency_seconds` | Gauge | Inference latency |

### Disable Observability

```bash
helm upgrade moshi-test . -f values-test.yaml \
  --set observability.enabled=false \
  --namespace moshi-test
```

### Resource Requirements

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| Prometheus | 250m | 500m | 1Gi | 2Gi |
| Metrics Sidecar | 100m | 500m | 128Mi | 512Mi |
| Grafana | 250m | 500m | 256Mi | 512Mi |

## Configuration Reference

### GPU Configuration

```yaml
backend:
  gpu:
    enabled: true       # Enable GPU support
    count: 1           # Number of GPUs
    type: nvidia.com/gpu # Resource type (nvidia.com/gpu or nvidia.com/gpu.shared)
    shared: false      # Enable time-slicing (requires cluster setup)
```

### Observability Configuration

```yaml
observability:
  enabled: false  # Master toggle
  
  prometheus:
    enabled: true
    retention: 15d
    storage:
      size: 10Gi
      storageClass: "longhorn"
    resources:
      limits: { memory: "2Gi", cpu: "500m" }
      requests: { memory: "1Gi", cpu: "250m" }
  
  grafana:
    enabled: true
    adminPassword: "changeme"
    ingress:
      enabled: true
      host: grafana.moshi.homelab
