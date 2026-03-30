# Environment: `dev`

Terraform **root** for the development / lab account.

## Layout

- **`versions.tf`**, **`providers.tf`**, **`data.tf`**, **`main.tf`**, **`variables.tf`**, **`outputs.tf`** — symlinks to [`../common/`](../common/). Change `common/` or add env-only `.tf` next to the symlinks.
- **`terraform.secrets.auto.tfvars.example`** — copy to `terraform.secrets.auto.tfvars` (values for cluster + OIDC/Keycloak config).

## Workflow

1. Configure **backend** (S3 + DynamoDB or equivalent) — document in `docs/D2-reproducibility-guide.md`.  
2. Symlinks are created with `ln -sf ../common/<file> .` (see `common/README.md` if you add a new env).  
3. `terraform init && terraform apply`  
   **First deploy:** if the EKS cluster does not exist yet, Helm/Kubernetes data sources cannot reach the API — run  
   `terraform apply -target=module.vpc -target=module.eks`  
   once, then `terraform apply` (installs Argo CD via `helm_release`).

Note: `terraform/environments/dev/` currently contains local state files (`terraform.tfstate`, backups) — if you’re aiming for “clean account” reproducibility, recreate backend state per D2 rather than relying on the checked-in local state.

After deploy, you can generate/update kubeconfig with:
`terraform/environments/connect_to_eks.sh --env dev`
