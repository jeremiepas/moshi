## Why

The current Moshi Helm chart lacks a dedicated test environment configuration, making it difficult to validate changes before production deployment. Additionally, there's no observability stack for monitoring token throughput, audio latency, and GPU utilization, which are critical for understanding Moshi backend performance. GPU memory constraints (12GB limit) further necessitate a tested configuration with smaller quantized models.

## What Changes

- Add `values-test.yaml` with optimized test environment configuration using `kyutai/moshika-pytorch-q8` model (Q8 quantized, ~12GB VRAM)
- Add GPU time-slicing support in `backend-deployment.yaml` for optional multi-pod GPU sharing
- Add optional observability stack (Prometheus + Grafana) with log-based token metrics parsing
- Add Grafana dashboards for Moshi monitoring (token throughput, audio latency, GPU utilization)
- Add Prometheus sidecar container for parsing Moshi logs and exposing metrics
- Add chart dependency on `grafana` Helm chart

## Capabilities

### New Capabilities

- `test-environment`: Test environment configuration with Q8 quantized model, reduced resource limits, and proper ingress setup for `test.moshi.homelab`
- `gpu-time-slicing`: GPU sharing configuration supporting NVIDIA device plugin time-slicing, allowing multiple pods to share a single GPU
- `observability-stack`: Optional observability stack with Prometheus for log parsing, Grafana dashboards, and token/audio/GPU metrics collection

### Modified Capabilities

(No existing capabilities to modify - this is initial implementation)

## Impact

- **Files Created**:
  - `values-test.yaml`: Test environment values
  - `templates/observability/prometheus-deployment.yaml`
  - `templates/observability/prometheus-service.yaml`
  - `templates/observability/prometheus-configmap.yaml`
  - `templates/observability/grafana-deployment.yaml`
  - `templates/observability/grafana-service.yaml`
  - `templates/observability/grafana-ingress.yaml`
  - `templates/observability/_helpers.tpl`

- **Files Modified**:
  - `Chart.yaml`: Add Grafana chart dependency
  - `templates/backend-deployment.yaml`: Add GPU time-slicing annotations and resource types

- **Dependencies**:
  - `prometheus/prometheus:latest`: Sidecar for log parsing
  - `grafana/grafana`: Dashboard visualization (Helm chart)

- **Resource Requirements**:
  - Test environment: 5.5 CPU cores, 15Gi RAM, 11Gi storage, 1 GPU
  - GPU memory: ~10-12GB VRAM for Q8 model