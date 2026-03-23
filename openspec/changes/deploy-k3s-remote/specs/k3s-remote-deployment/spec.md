## ADDED Requirements

### Requirement: Remote K3s cluster kubeconfig configuration
The system SHALL provide a dedicated Kubernetes configuration file for connecting to the remote K3s cluster at `~/.kube/config-k3s-remote`.

#### Scenario: Kubeconfig file exists
- **WHEN** a user attempts to deploy to the remote cluster
- **THEN** the system SHALL reference the kubeconfig file at `~/.kube/config-k3s-remote`

#### Scenario: Kubeconfig is valid
- **WHEN** kubectl commands are executed with `--kubeconfig ~/.kube/config-k3s-remote`
- **THEN** the commands SHALL successfully connect to the remote K3s cluster

### Requirement: Remote-specific Helm values file
The system SHALL provide a `values-remote.yaml` file containing configuration defaults specific to the remote K3s cluster deployment.

#### Scenario: Values file structure
- **WHEN** the values-remote.yaml file is used
- **THEN** it SHALL follow the same structure and support the same configuration keys as values.yaml

#### Scenario: Domain configuration
- **WHEN** deploying to the remote cluster
- **THEN** the user SHALL be able to configure the ingress hostname via the `domain.subdomain` value

### Requirement: Deployment commands documentation
The system SHALL document the exact Helm and kubectl commands needed to deploy Moshi to the remote K3s cluster using the dedicated kubeconfig.

#### Scenario: Helm deployment command
- **WHEN** a user wants to deploy Moshi to the remote cluster
- **THEN** the documentation SHALL provide the exact `helm upgrade --install` command with the `--kubeconfig` flag

#### Scenario: Pre-deployment verification
- **WHEN** a user prepares to deploy
- **THEN** the documentation SHALL include steps to verify cluster connectivity (e.g., `kubectl get nodes`)

### Requirement: Values file separation
The system SHALL maintain separate values files for local and remote deployments to prevent configuration drift.

#### Scenario: Local values unchanged
- **WHEN** remote deployment configuration is created
- **THEN** the existing `values.yaml` and `values-test.yaml` files SHALL NOT be modified

#### Scenario: Remote values independent
- **WHEN** remote values are customized
- **THEN** changes SHALL NOT affect local deployment configurations