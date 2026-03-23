## Context

The Moshi project uses Helm charts for Kubernetes deployment. Currently, deployment assumes a local K3s cluster (montech) with default kubeconfig. The user has a separate kubeconfig file at `~/.kube/config-k3s-remote` for a remote K3s cluster that needs to be used for deployment.

The existing setup includes:
- Helm chart at `helm/moshi/` with `values.yaml` (default) and `values-test.yaml` (test environment)
- GPU support configuration for NVIDIA GPUs
- Traefik ingress with local domain resolution (e.g., `test.moshi.homelab`)

## Goals / Non-Goals

**Goals:**
- Create a `values-remote.yaml` file tailored for the remote K3s cluster
- Document deployment instructions for targeting the remote cluster using the dedicated kubeconfig
- Preserve existing local deployment workflow

**Non-Goals:**
- Modifying the Helm chart templates
- Changing GPU or storage configuration (same hardware assumptions)
- Setting up CI/CD pipelines
- Modifying the application code

## Decisions

### 1. Kubeconfig Selection Method
**Decision:** Use explicit `--kubeconfig` flag or `KUBECONFIG` environment variable in commands.

**Alternatives considered:**
- Merge kubeconfigs into single file: Rejected - keeps configs separate and prevents accidental deployment to wrong cluster
- Context switching with `kubectl config use-context`: Rejected - requires modifying the main kubeconfig, could affect other tools

**Rationale:** Explicit kubeconfig selection is the safest approach, ensuring intentional targeting of the remote cluster while keeping the local config untouched.

### 2. Values File Strategy
**Decision:** Create `helm/moshi/values-remote.yaml` following the existing pattern (`values-test.yaml`).

**Rationale:** Maintains consistency with the existing values file naming convention. Allows environment-specific overrides while keeping `values.yaml` as the base defaults.

### 3. Domain Configuration
**Decision:** Use a configurable `domain.subdomain` value for ingress hostnames.

**Rationale:** The `values-test.yaml` already demonstrates this pattern with `domain.subdomain: "test"`. For remote deployment, users can specify their own domain or use a placeholder that they can customize.

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Accidentally deploying to wrong cluster | Document clear verification steps (`kubectl get nodes` before deploy) |
| Remote cluster has different GPU/node setup | Start with minimal config, tune based on cluster resources |
| Ingress hostname conflicts | Use unique subdomain, document where to customize |
| Storage class unavailable | Document checking available storage classes before deployment |

## Open Questions

1. What domain/hostname should be used for the remote deployment? (Suggest: `moshi.remote` or let user configure)
2. Does the remote cluster have Longhorn or another storage provisioner? (Need to verify storage class)
3. Is GPU time-slicing configured on the remote cluster? (Affects `shared` configuration)