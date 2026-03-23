# Moshi Helm Chart Development Plan

## Overview

This document outlines the development plan for extending the Moshi Helm chart with test environment configuration, GPU time-slicing support, smaller model options (<12GB), and optional observability stack.

## 1. Test Environment Configuration (`values-test.yaml`)

### Domain Setup
- **Subdomain**: `test.moshi.homelab`
- **Ingress**: Configured for Traefik with TLS support

### Model Selection (<12GB)

**Selected Model**: `kyutai/moshika-pytorch-q8`
- **Type**: Int8 quantized PyTorch model (female voice)
- **VRAM Usage**: ~12GB (vs 24GB+ for BF16)
- **Alternative**: `kyutai/moshiko-pytorch-q8` (male voice variant)
- **Storage**: 20Gi (reduced from 50Gi)

**Benefits of Q8 Quantization**:
- 50% memory reduction
- Minimal quality loss
- Compatible with existing PyTorch backend
- Fits within 12GB GPU memory constraint

### Resource Configuration

```yaml
backend:
  resources:
    limits:
      memory: "12Gi"      # Reduced from 24Gi
      cpu: "4"            # Reduced from 8
      nvidia.com/gpu: 1
    requests:
      memory: "8Gi"       # Reduced from 16Gi
      cpu: "2"            # Reduced from 4

model:
  storage:
    size: 20Gi            # Reduced from 50Gi
```

## 2. GPU Time-Slicing Support

### Current State
- NVIDIA GPU Operator already configured on cluster
- Full GPU allocation per pod (`nvidia.com/gpu: 1`)

### Time-Slicing Configuration

**For Multi-Pod GPU Sharing**:

```yaml
backend:
  gpu:
    enabled: true
    count: 1
    type: nvidia.com/gpu
    # Time-slicing configuration (when cluster supports it)
    replicas: 1           # Increase for time-sliced sharing
    shared: false         # Set to true for time-slicing
```

**Cluster Requirements**:
Time-slicing requires NVIDIA device plugin configuration. The cluster admin must apply:

```yaml
# nvidia-device-plugin-config.yaml
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

**Resource Type for Time-Slicing**:
When enabled, use `nvidia.com/gpu.shared` instead of `nvidia.com/gpu`.

## 3. Observability Stack (Optional)

### Architecture

```
+─────────────────┐     +──────────────────┐     +─────────────────┐
│  Moshi Backend  │────▶│ Prometheus       │────▶│  Grafana        │
│  (Log Output)   │     │ (Log Parser)     │     │  (Dashboards)   │
+─────────────────┘     +──────────────────┘     +─────────────────┘
                               │
                               ▼
                        Token Metrics
                        - tokens/sec
                        - audio frames
                        - latency
```

### Configuration

```yaml
observability:
  enabled: false  # Toggle to enable/disable entire stack
  
  prometheus:
    enabled: true
    retention: 15d
    storage:
      size: 10Gi
      storageClass: "longhorn"
  
  grafana:
    enabled: true
    ingress:
      enabled: true
      className: "traefik"
      host: grafana.moshi.homelab
    adminPassword: "changeme"
```

### Token Metrics Strategy

Since Moshi backend doesn't expose native Prometheus metrics, implement **log parsing approach**:

**Metrics to Capture**:
1. `moshi_text_tokens_total` - Count of text tokens generated
2. `moshi_audio_frames_total` - Count of audio frames processed
3. `moshi_inference_latency_seconds` - Response time per frame
4. `moshi_websocket_connections` - Active WebSocket connections

**Log Pattern Matching**:
```
Pattern: "text token '(.*?)'"
Action: Increment text token counter

Pattern: "steps: (\d+), token per sec: ([\d.]+)"
Action: Record throughput metrics
```

### Components

#### 1. Prometheus Sidecar
- **Image**: `prom/prometheus:latest` or custom log exporter
- **Function**: Parse Moshi logs and expose metrics endpoint
- **Port**: 9090
- **Scrape Interval**: 15s

#### 2. Grafana Instance
- **Source**: prometheus-community/grafana Helm chart
- **Dashboards**: Pre-configured Moshi dashboards
  - Token throughput
  - Audio latency
  - GPU utilization
  - Memory usage

## 4. Implementation Files

### New Files to Create

```
helm/moshi/
├── values-test.yaml              # Test environment values
├── PLAN.md                       # This document
├── templates/
│   ├── observability/
│   │   ├── _helpers.tpl         # Observability helper templates
│   │   ├── prometheus-deployment.yaml
│   │   ├── prometheus-service.yaml
│   │   ├── prometheus-configmap.yaml
│   │   ├── grafana-deployment.yaml
│   │   ├── grafana-service.yaml
│   │   └── grafana-ingress.yaml
│   └── backend-deployment.yaml   # Update for GPU time-slicing
└── Chart.yaml                    # Update dependencies
```

### Chart Dependencies Update

```yaml
# Chart.yaml
dependencies:
  - name: grafana
    version: 7.3.x
    repository: https://grafana.github.io/helm-charts
    condition: observability.grafana.enabled
```

## 5. Deployment Workflow

### Quick Start (Test Environment)

```bash
# 1. Update dependencies
helm dependency update

# 2. Install with test values
helm install moshi-test . -f values-test.yaml --namespace moshi-test --create-namespace

# 3. Access applications
kubectl port-forward svc/moshi-test-webui 8080:80 -n moshi-test
# Open: http://localhost:8080

# 4. Enable observability (optional)
helm upgrade moshi-test . -f values-test.yaml --set observability.enabled=true
```

### With Observability

```bash
# Enable observability stack
helm install moshi-test . -f values-test.yaml \
  --set observability.enabled=true \
  --set observability.grafana.adminPassword=secure-password \
  --namespace moshi-test --create-namespace

# Access Grafana
# URL: http://grafana.moshi.homelab (or port-forward)
```

## 6. Monitoring Endpoints

### Token Metrics Endpoint
- **URL**: `http://moshi-test-prometheus:9090/metrics`
- **Format**: Prometheus exposition format
- **Metrics Prefix**: `moshi_*`

### Grafana Dashboard
- **URL**: `http://grafana.moshi.homelab`
- **Default Login**: admin / changeme
- **Data Source**: Prometheus
- **Dashboards**: 
  - "Moshi Overview"
  - "Token Throughput"
  - "GPU Utilization"

## 7. Resource Estimates

### Test Environment

| Component | CPU | Memory | Storage | GPU |
|-----------|-----|--------|---------|-----|
| Moshi Backend | 4 | 12Gi | - | 1 |
| WebUI | 0.5 | 512Mi | - | - |
| Prometheus | 0.5 | 2Gi | 10Gi | - |
| Grafana | 0.5 | 512Mi | 1Gi | - |
| **Total** | **5.5** | **15Gi** | **11Gi** | **1** |

### Notes
- GPU memory: Q8 model uses ~10-12GB VRAM
- Storage: Model cache (20Gi) + Prometheus (10Gi) + Grafana (1Gi)

## 8. Next Steps

### Phase 1: Core Test Environment
1. [ ] Create `values-test.yaml`
2. [ ] Update `backend-deployment.yaml` for GPU time-slicing support
3. [ ] Test deployment on `test.moshi.homelab`

### Phase 2: Observability (Optional)
1. [ ] Create Prometheus templates
2. [ ] Create Grafana templates
3. [ ] Add log parser sidecar
4. [ ] Create default dashboards
5. [ ] Update `Chart.yaml` dependencies

### Phase 3: Documentation
1. [ ] Update `README.md` with new features
2. [ ] Document observability setup
3. [ ] Add troubleshooting guide

## 9. Validation Checklist

- [ ] Moshi backend starts with Q8 model
- [ ] GPU memory usage stays under 12GB
- [ ] WebUI accessible at `test.moshi.homelab`
- [ ] Prometheus metrics endpoint responding
- [ ] Grafana dashboards showing token metrics
- [ ] Grafana accessible at `grafana.moshi.homelab`
- [ ] GPU time-slicing works (if cluster configured)

## References

- [Moshi Models on HuggingFace](https://huggingface.co/collections/kyutai/moshi-v01-release-66eaeaf3302bef6bd9ad7acd)
- [NVIDIA GPU Time-Slicing](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/gpu-sharing/time-slicing.html)
- [Prometheus Log Parser Pattern](https://github.com/prometheus/prometheus/tree/main/documentation/examples)
- [Grafana Helm Chart](https://github.com/grafana/helm-charts/tree/main/charts/grafana)
