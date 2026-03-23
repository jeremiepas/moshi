## ADDED Requirements

### Requirement: Optional observability stack
The Helm chart SHALL provide an optional observability stack deployed only when explicitly enabled via `observability.enabled: true`.

#### Scenario: Observability disabled (default)
- **WHEN** deploying with default values
- **THEN** `observability.enabled` SHALL default to `false`
- **AND** no Prometheus or Grafana resources SHALL be created
- **AND** Moshi backend SHALL deploy normally

#### Scenario: Observability enabled
- **WHEN** user sets `observability.enabled: true`
- **THEN** Prometheus resources SHALL be deployed
- **AND** Grafana resources SHALL be deployed
- **AND** metrics collection SHALL start automatically

### Requirement: Prometheus sidecar for log parsing
The observability stack SHALL use a Prometheus sidecar container to parse Moshi backend logs and expose metrics endpoint.

#### Scenario: Sidecar deployment
- **WHEN** observability is enabled
- **THEN** Prometheus sidecar container SHALL be deployed alongside Moshi backend
- **AND** sidecar SHALL read Moshi logs from shared volume or stdout
- **AND** sidecar SHALL expose `/metrics` endpoint on port 9090

#### Scenario: Log pattern parsing
- **WHEN** Moshi backend logs token information
- **THEN** sidecar SHALL parse log entries matching:
  - `text token '(.*?)'` → increment `moshi_text_tokens_total` counter
  - `steps: (\d+), token per sec: ([\d.]+)` → record `moshi_tokens_per_sec` gauge
  - `audio_frame` → increment `moshi_audio_frames_total` counter

#### Scenario: Metrics endpoint format
- **WHEN** Prometheus server scrapes `/metrics`
- **THEN** metrics SHALL be in Prometheus exposition format
- **AND** all metrics SHALL use `moshi_` prefix
- **AND** metrics SHALL include timestamps

### Requirement: Grafana with preconfigured Moshi dashboards
The observability stack SHALL deploy Grafana with preconfigured dashboards for Moshi monitoring.

#### Scenario: Grafana deployment
- **WHEN** observability is enabled
- **THEN** Grafana SHALL be deployed via official Helm chart
- **AND** Grafana SHALL be accessible via ingress at `grafana.moshi.homelab`
- **AND** default credentials SHALL be configurable in values

#### Scenario: Dashboard provisioning
- **WHEN** Grafana starts
- **THEN** following dashboards SHALL be pre-configured:
  - Moshi Overview (token throughput, audio frames, latency)
  - GPU Utilization (memory usage, compute utilization)
  - Resource Usage (CPU, memory over time)

#### Scenario: Dashboard data source
- **WHEN** Grafana dashboards load
- **THEN** Prometheus SHALL be configured as default data source
- **AND** data source connection SHALL succeed automatically

### Requirement: Metrics collection via Prometheus
The observability stack SHALL deploy Prometheus configured to scrape metrics from the Moshi backend sidecar.

#### Scenario: Prometheus configuration
- **WHEN** observability is enabled
- **THEN** Prometheus SHALL be configured with:
  - Scrape interval: 15 seconds
  - Retention: 15 days (configurable)
  - Target: Moshi backend sidecar on port 9090

#### Scenario: Prometheus storage
- **WHEN** Prometheus is deployed
- **THEN** persistent volume SHALL be created with 10Gi storage (configurable)
- **AND** storage class SHALL use cluster default or `observability.prometheus.storage.storageClass`

### Requirement: Observability resource configuration
The Helm chart SHALL allow configuration of observability resource limits and requests.

#### Scenario: Prometheus resources
- **WHEN** user configures `observability.prometheus.resources`
- **THEN** Prometheus container SHALL use specified CPU and memory limits
- **AND** defaults SHALL be:
  - CPU request: 500m
  - Memory request: 2Gi
  - CPU limit: 1
  - Memory limit: 4Gi

#### Scenario: Grafana resources
- **WHEN** user configures `observability.grafana.resources`
- **THEN** Grafana container SHALL use specified resources
- **AND** defaults SHALL be:
  - CPU request: 100m
  - Memory request: 256Mi
  - CPU limit: 500m
  - Memory limit: 512Mi

### Requirement: Ingress configuration for monitoring
The observability stack SHALL expose Grafana via ingress with configurable hostname.

#### Scenario: Grafana ingress
- **WHEN** `observability.grafana.ingress.enabled: true`
- **THEN** ingress SHALL be created for host specified in `observability.grafana.ingress.host`
- **AND** default host SHALL be `grafana.moshi.homelab`
- **AND** ingress class SHALL be `traefik`
- **AND** TLS SHALL be enabled

#### Scenario: Ingress disabled
- **WHEN** `observability.grafana.ingress.enabled: false`
- **THEN** no ingress SHALL be created for Grafana
- **AND** user SHALL access Grafana via port-forward or ClusterIP service

### Requirement: Sidecar resource isolation
The Prometheus sidecar SHALL have independent resource constraints to prevent impact on Moshi backend performance.

#### Scenario: Sidecar resource limits
- **WHEN** observability is enabled
- **THEN** sidecar container SHALL have:
  - CPU request: 100m
  - Memory request: 128Mi
  - CPU limit: 500m
  - Memory limit: 512Mi
- **AND** sidecar resources SHALL NOT count toward Moshi backend limits

### Requirement: Observability health checks
The Prometheus sidecar SHALL expose health endpoint for monitoring.

#### Scenario: Sidecar health check
- **WHEN** Kubernetes liveness probe queries sidecar health endpoint
- **THEN** sidecar SHALL respond with HTTP 200 if log parsing is active
- **AND** sidecar SHALL respond with HTTP 503 if parsing has failed