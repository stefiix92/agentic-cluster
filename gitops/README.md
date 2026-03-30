# GitOps (FR-2, FR-3)

Kubernetes **desired state** consumed by Argo CD after bootstrap.

| Path | Role |
| ------ | ------ |
| `argocd/` | Argo CD **Application** / **AppProject** manifests (Helm install + chart values live under **`terraform/environments/common/`**) |
| `argocd/applications/<env>/` | Child `Application` / `AppProject` CRs (app-of-apps **root** is Terraform `helm_release.argocd` `extraObjects`, not stored here) |
| `platform/database/` | Kustomize `base/` + `overlays/<env>/` → PostgreSQL for **`database`** |
| `platform/identity/` | Kustomize `base/` + `overlays/<env>/` → Keycloak for **`identity`** |
| `platform/ingress/` | Kustomize `base/` + `overlays/<env>/` → public ALB Ingresses for Argo CD (**`argo`**) + Keycloak (**`identity`**) |

**Rule:** Application workloads (Postgres, Keycloak, etc.) should be referenced from Argo CD `Application` manifests, not one-off `kubectl apply`, except where explicitly documented in D3/D2.
