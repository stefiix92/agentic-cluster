# Argo CD (namespace `argo`)

**Install / Helm values:** Terraform — `terraform/environments/common/main.tf` (`helm_release.argocd`) + `terraform/environments/common/argocd-helm-values.yaml.tftpl` (OIDC/RBAC) and sensitive client secret merge in `main.tf`.

This tree holds **GitOps** only: Argo watches `gitops/argocd/applications/<env>/*.yaml` (child `Application` / `AppProject`; app-of-apps root is created by Terraform).

Document exact commands in `docs/D2-reproducibility-guide.md`.

Suggested layout:

- `applications/<env>/` — Child `Application` / `AppProject` CRs synced from Git
- `<env>/project-platform.yaml` — `AppProject` constraints (sync-wave `-1`)
- `<env>/platform-database.yaml` — `Application` targeting `gitops/platform/database/overlays/<env>` (sync-wave `0`)
- `<env>/platform-identity.yaml` — `Application` targeting `gitops/platform/identity/overlays/<env>` (sync-wave `1`)
- `<env>/platform-ingress.yaml` — `Application` targeting `gitops/platform/ingress/overlays/<env>` (sync-wave `2`; ALB via `aws-load-balancer-controller`)

