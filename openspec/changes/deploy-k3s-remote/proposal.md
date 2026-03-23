## Why

Deploy the Moshi application to a remote K3s cluster instead of a local cluster. Currently the Helm chart and deployment scripts assume a local K3s setup (montech), but the user needs to deploy to a remote K3s cluster using a separate kubeconfig file (`~/.kube/config-k3s-remote`). This enables Moshi to run on a dedicated remote infrastructure with proper GPU support.

## What Changes

- Update deployment documentation and scripts to support remote K3s cluster deployment
- Add kubeconfig selection mechanism for targeting specific clusters
- Create or update values file for remote cluster configuration
- Ensure Helm commands reference the correct kubeconfig

## Capabilities

### New Capabilities

- `k3s-remote-deployment`: Configuration and documentation for deploying Moshi to a remote K3s cluster using a separate kubeconfig file

### Modified Capabilities

None - this is a new deployment target, no existing specs change requirements.

## Impact

- Deployment documentation
- Helm values files (new remote-specific values)
- Optional: deployment scripts or Makefile targets for remote cluster
- kubectl and helm commands will need `--kubeconfig` flag or KUBECONFIG environment variable