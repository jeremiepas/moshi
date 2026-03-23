## 1. Documentation

- [ ] 1.1 Create deployment documentation file (e.g., `docs/remote-deployment.md`) with step-by-step instructions
- [ ] 1.2 Document kubeconfig setup and verification steps
- [ ] 1.3 Add pre-flight checklist (verify cluster connectivity, check available storage classes, verify GPU resources)

## 2. Values Configuration

- [ ] 2.1 Create `helm/moshi/values-remote.yaml` based on `values-test.yaml` template
- [ ] 2.2 Configure domain.subdomain value for remote cluster (use placeholder or configurable value)
- [ ] 2.3 Review and document storageClass requirements for remote cluster
- [ ] 2.4 Verify GPU configuration matches remote cluster capabilities

## 3. Deployment Commands

- [ ] 3.1 Document Helm upgrade command with `--kubeconfig ~/.kube/config-k3s-remote`
- [ ] 3.2 Document namespace creation command for remote cluster
- [ ] 3.3 Provide example commands for:
  - [ ] 3.3.1 Verify cluster connectivity: `kubectl get nodes --kubeconfig ~/.kube/config-k3s-remote`
  - [ ] 3.3.2 Deploy Moshi: `helm upgrade --install moshi ./helm/moshi --kubeconfig ~/.kube/config-k3s-remote -f helm/moshi/values-remote.yaml`
  - [ ] 3.3.3 Check deployment status: `kubectl get pods --kubeconfig ~/.kube/config-k3s-remote`

## 4. Validation

- [ ] 4.1 Verify documentation accuracy with dry-run deployments
- [ ] 4.2 Test deployment to remote cluster using the documented process
- [ ] 4.3 Update README.md with link to remote deployment documentation