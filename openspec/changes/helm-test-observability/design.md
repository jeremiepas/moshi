## Context

The Moshi Helm chart currently provides production deployment configuration but lacks:
1. **Test environment isolation**: No separate values file for testing with smaller models
2. **Observability**: No metrics collection for token throughput, audio latency, or GPU utilization
3. **GPU efficiency**: No support for time-slicing to share GPU across multiple pods

The Moshi backend generates logs with token/s and latency metrics but doesn't expose native Prometheus endpoints. This design implements log-based metrics parsing using a Prometheus sidecar approach.

**Stakeholders**: Platform engineers deploying Moshi, SREs monitoring performance, developers validating changes

**Constraints**:
- Target GPU memory: 12GB (RTX 4070/4080 class)
- Must work with existing Traefik ingress
- Optional observability (must not break deployments without it)

## Goals / Non-Goals

**Goals:**
- Enable isolated test deployments with Q8 quantized model (<12GB VRAM)
- Provide optional observability stack for token/audio/GPU metrics
- Support GPU time-slicing for shared GPU environments
- Maintain backward compatibility with existing deployments

**Non-Goals:**
- Native Prometheus instrumentation in Moshi backend (requires upstream changes)
- Multi-GPU or MIG partitioning support
- Custom dashboard creation API (use standard Grafana dashboards)
- Alerting rules configuration (out of scope for v1)

## Decisions

### 1. Model Selection: Q8 Quantized PyTorch

**Decision**: Use `kyutai/moshika-pytorch-q8` as default for test environment

**Rationale**: 
- BF16 model requires 24GB+ VRAM (exceeds 12GB constraint)
- Q8 provides 50% memory reduction with minimal quality loss
- PyTorch backend is already supported in chart
- Alternative considered: `moshiko-pytorch-q8` (male voice) - offered as user option in values

### 2. Metrics Collection: Log Parsing Sidecar

**Decision**: Deploy Prometheus sidecar container to parse Moshi logs and expose metrics endpoint

**Architecture**:
```
Moshi Container ──stdout──▶ Log Stream
                                  │
Prometheus Sidecar ──parse──▶ /metrics endpoint
                                  │
                            Prometheus scrape
```

**Rationale**:
- Moshi doesn't expose `/metrics` natively
- Log parsing avoids code changes to Moshi
- Sidecar pattern keeps containers decoupled
- Alternative considered: Fluent Bit + Prometheus → rejected (adds complexity, no need for log aggregation)

**Log Pattern Matching**:
```
Pattern: "text token '(.*?)'" → Counter: moshi_text_tokens_total
Pattern: "steps: (\d+), token per sec: ([\d.]+)" → Gauge: moshi_tokens_per_sec
Pattern: "audio_frame" → Counter: moshi_audio_frames_total
```

### 3. GPU Time-Slicing: Opt-In via Resource Type

**Decision**: Use `nvidia.com/gpu.shared` resource type when `backend.gpu.shared: true`

**Rationale**:
- Requires cluster-level NVIDIA device plugin configuration (not Helm-managed)
- Explicit opt-in prevents accidental GPU oversubscription
- Alternative considered: Automatic time-slicing config → rejected (cluster admins manage GPU operator)

**Configuration flow**:
1. Cluster admin configures NVIDIA device plugin for time-slicing
2. User sets `backend.gpu.shared: true` in values
3. Deployment uses `nvidia.com/gpu.shared` resource type

### 4. Observability: Conditionally Deployed

**Decision**: Use `observability.enabled: false` by default, deploy Prometheus/Grafana only when enabled

**Rationale**:
- Not all deployments need observability
- Reduces resource footprint for minimal test deployments
- Uses `{{- if .Values.observability.enabled }}` conditionals in templates
- Grafana deployed from official Helm chart (not custom templates)

**Conditional Resources**:
- Prometheus ConfigMap (scrape config, log parser rules)
- Prometheus Deployment + Service
- Grafana sub-chart with ingress

## Risks / Trade-offs

### [Risk] Log Parsing Reliability
Log format changes in Moshi could break metrics collection.
**Mitigation**: Document log patterns explicitly, add metric validation in dashboards, consider upstream Prometheus instrumentation contribution

### [Risk] GPU Time-Slicing Requires Cluster Setup
Users assume time-slicing works without cluster-level configuration.
**Mitigation**: Clear documentation in values.yaml comments, README section explaining cluster prerequisites

### [Risk] Q8 Model Quality Degradation
Quantized model may produce lower quality responses.
**Mitigation**: Document this as test-only model, provide docs on switching to BF16 for production

### [Risk] Sidecar Log Parsing Overhead
Prometheus sidecar adds CPU/memory overhead.
**Mitigation**: Resource requests/limits on sidecar container (500m CPU, 512Mi memory), make observability stack optional

### [Trade-off] No Native Metrics
Log-based metrics are less precise than native instrumentation.
**Trade-off**: Acceptable for v1 use case, plan upstream contribution for native Prometheus metrics

## Migration Plan

### Deployment Steps

1. **Phase 1: Test Environment** (Required)
   ```bash
   helm dependency update
   helm install moshi-test . -f values-test.yaml --namespace moshi-test --create-namespace
   ```
   
2. **Phase 2: Enable Observability** (Optional)
   ```bash
   helm upgrade moshi-test . -f values-test.yaml \
     --set observability.enabled=true \
     --set observability.grafana.adminPassword=<secure>
   ```

3. **Phase 3: GPU Time-Slicing** (Requires cluster setup)
   - Cluster admin applies NVIDIA device plugin config
   - Add to values: `backend.gpu.shared: true`
   - Upgrade release

### Rollback Strategy

- **Disable observability**: `helm upgrade moshi-test . -f values-test.yaml --set observability.enabled=false`
- **Revert to production model**: Switch values file to production configuration
- **Uninstall test**: `helm uninstall moshi-test -n moshi-test`

### Validation Checklist

- [ ] Q8 model loads successfully (<12GB VRAM)
- [ ] WebUI accessible at `test.moshi.homelab`
- [ ] Prometheus sidecar starts and parses logs
- [ ] Grafana dashboards show token metrics
- [ ] Time-slicing works (if cluster configured)

## Open Questions

1. **Grafana dashboard storage**: Should dashboards be ConfigMap-managed or loaded from filesystem?
   - **Proposed**: ConfigMap with dashboard JSON for v1
   - Alternative: Sidecar dashboard loader (adds complexity)

2. **Token metric granularity**: Track per-request metrics or aggregate only?
   - **Proposed**: Aggregate counters for v1, consider histogram for latency percentiles
   
3. **Prometheus retention**: Default 15d or configurable?
   - **Proposed**: Configurable via `observability.prometheus.retention`