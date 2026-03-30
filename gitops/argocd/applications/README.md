# Argo CD applications

One directory per environment (**one Argo CD per cluster**; no shared control plane).

**Bootstrap:** the **`root-platform`** app-of-apps `Application` is created by **Terraform** (`helm_release.argocd`, Helm `extraObjects` + `locals` in `terraform/environments/common/main.tf`). This folder holds **only** the child manifests Argo syncs from Git (`AppProject`, `platform-*`).

| Pattern | Purpose |
| -------- | --------- |
| **`<env>/project-*.yaml`** | `AppProject` constraints (allowed repos, destinations). |
| **`<env>/platform-*.yaml`** | `Application` resources for `database`, `identity`, and `ingress` stacks; `spec.source.path` targets **`gitops/platform/*/overlays/<env>`** (Kustomize). |

In the current code, `repoURL` / `targetRevision` for the `root-platform` app-of-apps `Application` are set in `terraform/environments/common/main.tf` locals (and are not read from `argocd_gitops_repo_url` variables).
If you fork this repo, update those values in Terraform.

Adding **prod**: add `applications/prod/` manifests, `platform/*/overlays/prod`, and a Terraform env whose `environment_name` / `argocd_gitops_*` match that layout.
