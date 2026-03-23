## 1. Test Environment Configuration

- [x] 1.1 Create `values-test.yaml` with Q8 model configuration (`kyutai/moshika-pytorch-q8`)
- [x] 1.2 Configure reduced resource limits (12Gi memory, 4 CPU limit, 8Gi/2 CPU requests)
- [x] 1.3 Set model storage size to 20Gi
- [x] 1.4 Configure ingress for `test.moshi.homelab` with Traefik and TLS
- [x] 1.5 Verify model alternative option (`moshiko-pytorch-q8`) documentation

## 2. GPU Time-Slicing Support

- [x] 2.1 Add GPU configuration values to `values.yaml` (`backend.gpu.enabled`, `backend.gpu.count`, `backend.gpu.type`, `backend.gpu.shared`)
- [x] 2.2 Update `templates/backend-deployment.yaml` to use conditional resource type (`nvidia.com/gpu` vs `nvidia.com/gpu.shared`)
- [x] 2.3 Set default values for GPU configuration (enabled: true, count: 1, shared: false)
- [x] 2.4 Add documentation in README about cluster-level NVIDIA device plugin requirements for time-slicing

## 3. Observability Stack - Prometheus Sidecar

- [x] 3.1 Create `templates/observability/_helpers.tpl` with observability helper functions
- [x] 3.2 Create `templates/observability/prometheus-configmap.yaml` with log parsing rules
- [x] 3.3 Implement log pattern matching for `moshi_text_tokens_total` counter
- [x] 3.4 Implement log pattern matching for `moshi_tokens_per_sec` gauge
- [x] 3.5 Implement log pattern matching for `moshi_audio_frames_total` counter
- [x] 3.6 Create `templates/observability/prometheus-deployment.yaml` with sidecar container
- [x] 3.7 Create `templates/observability/prometheus-service.yaml` exposing metrics endpoint on port 9090
- [x] 3.8 Configure sidecar resource limits (CPU: 100m-500m, Memory: 128Mi-512Mi)
- [x] 3.9 Add liveness probe to sidecar health endpoint

## 4. Observability Stack - Prometheus Server

- [x] 4.1 Configure Prometheus scrape target for Moshi backend sidecar (15s interval)
- [x] 4.2 Set default retention to 15 days
- [x] 4.3 Configure persistent storage (10Gi default)
- [x] 4.4 Add storage class configuration option (`observability.prometheus.storage.storageClass`)

## 5. Observability Stack - Grafana

- [x] 5.1 Add Grafana Helm chart dependency to `Chart.yaml` (version 7.3.x)
- [x] 5.2 Configure Grafana values for ingress (`grafana.moshi.homelab`, Traefik, TLS)
- [x] 5.3 Set default admin password configuration
- [x] 5.4 Configure Grafana resource limits (CPU: 100m-500m, Memory: 256Mi-512Mi)
- [x] 5.5 Create ConfigMap for Moshi Overview dashboard (token throughput, audio frames, latency)
- [x] 5.6 Create ConfigMap for GPU Utilization dashboard (memory usage, compute utilization)
- [x] 5.7 Create ConfigMap for Resource Usage dashboard (CPU, memory over time)
- [x] 5.8 Configure Prometheus as default data source

## 6. Observability Conditional Deployment

- [x] 6.1 Add `observability.enabled` toggle to `values.yaml` (default: false)
- [x] 6.2 Wrap all observability templates with `{{- if .Values.observability.enabled }}`
- [x] 6.3 Ensure Moshi backend deploys correctly when observability is disabled
- [ ] 6.4 Test deployment with `observability.enabled=true`
- [ ] 6.5 Verify all observability resources deploy when enabled

## 7. Chart Updates and Dependencies

- [x] 7.1 Update `Chart.yaml` with Grafana chart dependency (`grafana` chart, version 7.3.x, repository https://grafana.github.io/helm-charts)
- [x] 7.2 Add condition to dependency: `observability.grafana.enabled`
- [x] 7.3 Document new values in `values.yaml` with inline comments
- [x] 7.4 Update `README.md` with test environment deployment instructions
- [x] 7.5 Add observability deployment section to README
- [x] 7.6 Add GPU time-slicing prerequisites section to README

## 8. Testing and Validation

- [ ] 8.1 Run `helm dependency update` to fetch Grafana chart
- [ ] 8.2 Test dry-run install: `helm install moshi-test . -f values-test.yaml --dry-run`
- [ ] 8.3 Deploy to test namespace: `helm install moshi-test . -f values-test.yaml --namespace moshi-test --create-namespace`
- [ ] 8.4 Verify Q8 model loads successfully and GPU memory stays under 12GB
- [ ] 8.5 Verify WebUI accessible at `test.moshi.homelab`
- [ ] 8.6 Enable observability and verify Prometheus sidecar starts
- [ ] 8.7 Verify Grafana accessible at `grafana.moshi.homelab`
- [ ] 8.8 Verify dashboards show token metrics (after generating traffic)
- [ ] 8.9 Test time-slicing configuration (if cluster supports it)
- [ ] 8.10 Validate rollback: disable observability with `--set observability.enabled=false`