## ADDED Requirements

### Requirement: Test environment uses Q8 quantized model
The Helm chart SHALL provide a `values-test.yaml` file that configures the test environment to use `kyutai/moshika-pytorch-q8` (Q8 quantized) model by default, ensuring GPU memory usage remains under 12GB.

#### Scenario: Test deployment with Q8 model
- **WHEN** deploying with `helm install moshi-test . -f values-test.yaml`
- **THEN** the backend container SHALL pull and run the `kyutai/moshika-pytorch-q8` model
- **AND** GPU memory usage SHALL NOT exceed 12GB

#### Scenario: Alternative model selection
- **WHEN** user sets `model.name: kyutai/moshiko-pytorch-q8` in values override
- **THEN** the backend SHALL use the male voice variant instead

### Requirement: Reduced resource limits for test environment
The test environment SHALL have optimized resource limits suitable for development and validation, distinct from production values.

#### Scenario: Memory and CPU limits
- **WHEN** deploying with `values-test.yaml`
- **THEN** backend container SHALL have memory limit of 12Gi (vs 24Gi production)
- **AND** CPU limit SHALL be 4 cores (vs 8 production)
- **AND** memory request SHALL be 8Gi (vs 16Gi production)
- **AND** CPU request SHALL be 2 cores (vs 4 production)

#### Scenario: Model storage size
- **WHEN** deploying with `values-test.yaml`
- **THEN** persistent volume claim for model storage SHALL be 20Gi (vs 50Gi production)

### Requirement: Test environment ingress configuration
The Helm chart SHALL configure ingress for the test environment subdomain `test.moshi.homelab` with Traefik TLS support.

#### Scenario: Test ingress creation
- **WHEN** deploying with `values-test.yaml`
- **THEN** ingress resource SHALL be created with host `test.moshi.homelab`
- **AND** ingress SHALL use Traefik ingress class
- **AND** TLS SHALL be enabled for the test domain

### Requirement: Test environment isolation
The test environment SHALL be deployable in a separate namespace with isolated resources from production deployments.

#### Scenario: Namespace creation
- **WHEN** deploying with `--namespace moshi-test --create-namespace`
- **THEN** namespace `moshi-test` SHALL be created
- **AND** all resources SHALL be deployed in the `moshi-test` namespace
- **AND** resources SHALL NOT conflict with production namespace resources