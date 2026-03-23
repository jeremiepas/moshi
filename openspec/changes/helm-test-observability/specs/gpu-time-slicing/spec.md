## ADDED Requirements

### Requirement: GPU time-slicing support
The Helm chart SHALL support NVIDIA GPU time-slicing configuration to allow multiple pods to share a single GPU when cluster-level configuration permits.

#### Scenario: Standard GPU allocation
- **WHEN** `backend.gpu.shared: false` (default)
- **THEN** deployment SHALL request `nvidia.com/gpu: 1` resource type
- **AND** pod SHALL have exclusive GPU access

#### Scenario: Time-sliced GPU allocation
- **WHEN** `backend.gpu.shared: true`
- **THEN** deployment SHALL request `nvidia.com/gpu.shared: 1` resource type
- **AND** pod SHALL be configured for time-sliced GPU sharing

### Requirement: GPU time-slicing is explicitly opt-in
The Helm chart SHALL default to exclusive GPU allocation, requiring explicit user configuration to enable time-slicing.

#### Scenario: Default configuration
- **WHEN** no GPU configuration is specified in values
- **THEN** `backend.gpu.shared` SHALL default to `false`
- **AND** deployment SHALL use `nvidia.com/gpu` resource type

#### Scenario: User enables time-slicing
- **WHEN** user sets `backend.gpu.shared: true`
- **THEN** deployment template SHALL change resource type to `nvidia.com/gpu.shared`
- **AND** deployment SHALL NOT modify cluster-level GPU operator configuration

### Requirement: GPU configuration values
The Helm chart SHALL provide structured GPU configuration values for flexible deployment scenarios.

#### Scenario: GPU configuration structure
- **WHEN** user configures GPU settings in values.yaml
- **THEN** following values SHALL be available:
  - `backend.gpu.enabled: true` (default)
  - `backend.gpu.count: 1` (number of GPUs)
  - `backend.gpu.type: nvidia.com/gpu` (resource type)
  - `backend.gpu.shared: false` (time-slicing toggle)

#### Scenario: Multiple GPU allocation
- **WHEN** user sets `backend.gpu.count: 2` AND `backend.gpu.shared: false`
- **THEN** deployment SHALL request `nvidia.com/gpu: 2`
- **AND** pod SHALL have exclusive access to 2 GPUs

### Requirement: Cluster prerequisite documentation
The Helm chart documentation SHALL clearly state that GPU time-slicing requires cluster-level NVIDIA device plugin configuration.

#### Scenario: Time-slicing without cluster setup
- **WHEN** user sets `backend.gpu.shared: true` on cluster without time-slicing configured
- **THEN** deployment SHALL fail at pod scheduling stage with resource unavailable error
- **AND** documentation SHALL explain required cluster-level configuration in README