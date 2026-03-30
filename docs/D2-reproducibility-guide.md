# D2 — Reproducibility guide

This is the “rebuild from zero” path for one environment (currently documented for `dev`).

## Prerequisites

- AWS access for the target account
  - either long-lived user credentials (`ACCESS_KEY_ID` / `SECRET_ACCESS_KEY`)
  - or an IAM role you can assume (`sts:AssumeRole`)
- Local tooling
  - `terraform >= 1.14.0`
  - `kubectl >= 1.26`
  - `helm >= 3.13.0`
  - `kubeseal` (for re-sealing `SealedSecret` manifests; see below)
  - optional: `awscli`, `terragrunt`

## What this guide assumes

- Terraform installs `sealed-secrets`, Argo CD, and the Argo “root app-of-apps”.
- Argo CD sync order is driven by sync waves:
  - `platform-database` (PostgreSQL) → `platform-identity` (Keycloak) → `platform-ingress` (public ALBs)
- The repo stores `SealedSecret` YAMLs for the platform secrets under:
  - `gitops/platform/database/overlays/dev/postgres-secret.yaml`
  - `gitops/platform/identity/overlays/dev/keycloak-secret.yaml`
- Because each cluster has a different sealed-secrets private key, you must re-generate (re-seal) those YAMLs per cluster.

## Step-by-step

### 1. Clone repo + prepare Terraform inputs

```bash
git clone <this-repo-url>
cd agentic-cluster
```

Environment in this repo is anchored at `terraform/environments/dev/`.

1. Copy secrets tfvars template:
   - `terraform/environments/dev/terraform.secrets.auto.tfvars.example`
   - → `terraform/environments/dev/terraform.secrets.auto.tfvars`
2. Fill in at least:
   - `kubernetes_api_allowed_cidrs`
   - `argocd_public_url` (placeholder for the first apply; you will overwrite after ALB DNS exists)
   - `argocd_oidc_issuer` (placeholder; you will overwrite after Keycloak ingress exists)
   - `argocd_oidc_client_id` (must match Keycloak client later)
   - `argocd_oidc_client_secret` can be a placeholder for now; it will be replaced after you create the Keycloak client in Step 7
3. Ensure `terraform/environments/<env>/` symlinks exist for the shared root modules:

```bash
cd terraform/environments/dev
ln -sf ../common/versions.tf .
ln -sf ../common/providers.tf .
ln -sf ../common/data.tf .
ln -sf ../common/main.tf .
ln -sf ../common/variables.tf .
ln -sf ../common/outputs.tf .
```

Important (Terraform backend reality check):

- `terraform/environments/dev/` currently uses *local* state (`terraform.tfstate` + backups) checked into the repo; there is no remote backend config wired by default.
- If you want “clean account” reproducibility (no reliance on checked-in local state), you need to add a real backend (for example S3 + DynamoDB locking) and document the exact backend config + initialization in this D2 guide (see the pointer from `terraform/environments/dev/README.md`).

### 2. Provision infra + install “platform bootstrap” (FR-1 → FR-2)

```bash
cd terraform/environments/dev
terraform init
terraform apply
```

Notes:

- If the EKS cluster does not exist yet, Helm/Kubernetes data sources won’t be able to reach the API on the first run. In that case run once:
  - `terraform apply -target=module.vpc -target=module.eks`
  - then re-run `terraform apply`

Terraform installs (in `terraform/environments/common/main.tf`):

- `sealed-secrets` Helm release
- `aws-load-balancer-controller`
- `argocd` into namespace `argo`

### 3. Connect to the cluster

```bash
terraform/environments/connect_to_eks.sh --env dev
```

This runs `aws eks update-kubeconfig` using the EKS cluster name + region from the Terraform state.

### 4. SealedSecrets chicken-and-egg (re-seal for *this* cluster)

Your GitOps workloads depend on `SealedSecret` objects being decryptable by the `sealed-secrets` controller in the target cluster.

Encrypted `encryptedData` in the repo is bound to the controller public key for the cluster that originally generated it, so on a brand-new cluster you must:

1. Fetch the controller’s cert / key material from the new cluster
2. Recreate the *plain* Kubernetes `Secret` manifests locally (client-side dry-run)
3. Pipe them into `kubeseal` to generate fresh `SealedSecret` YAMLs
4. Commit and push the regenerated YAMLs back to this repo

Key fields that must match across the two platform secrets:

- `KEYCLOAK_DB_PASSWORD` (Postgres init + Keycloak JDBC secret)
- `keycloak-credentials` secret keys:
  - `KEYCLOAK_ADMIN`
  - `KEYCLOAK_ADMIN_PASSWORD`
  - `KC_DB_PASSWORD`
- `postgres-credentials` secret keys:
  - `POSTGRES_USER`
  - `POSTGRES_PASSWORD`
  - `KEYCLOAK_DB_PASSWORD`

Example commands (adapt values, rotate freely):

```bash
export SEALED_CONTROLLER_NAME="sealed-secrets"
export SEALED_CONTROLLER_NAMESPACE="kube-system"
export SEALED_CONTROLLER_CERT_FILE="/tmp/sealed-secrets-cert.pem"

# Optional but explicit: fetch the controller's public cert (PEM) from this cluster.
# You can then pass it to kubeseal via `--cert` (instead of controller-name flags).
kubeseal \
  --fetch-cert \
  --controller-name "$SEALED_CONTROLLER_NAME" \
  --controller-namespace "$SEALED_CONTROLLER_NAMESPACE" \
> "$SEALED_CONTROLLER_CERT_FILE"

# Pick plaintext values for this new cluster.
export KEYCLOAK_DB_PASSWORD="REPLACE_ME_STRONG"
export POSTGRES_USER="postgres"
export POSTGRES_PASSWORD="REPLACE_ME_STRONG"

export KEYCLOAK_ADMIN="admin"
export KEYCLOAK_ADMIN_PASSWORD="REPLACE_ME_STRONG"

# 1) Keycloak sealed secret (identity namespace)
kubectl -n identity create secret generic keycloak-credentials \
  --from-literal=KEYCLOAK_ADMIN="$KEYCLOAK_ADMIN" \
  --from-literal=KEYCLOAK_ADMIN_PASSWORD="$KEYCLOAK_ADMIN_PASSWORD" \
  --from-literal=KC_DB_PASSWORD="$KEYCLOAK_DB_PASSWORD" \
  --dry-run=client -o yaml \
| kubeseal \
  --cert "$SEALED_CONTROLLER_CERT_FILE" \
  --format yaml \
> gitops/platform/identity/overlays/dev/keycloak-secret.yaml

# 2) Postgres sealed secret (database namespace)
kubectl -n database create secret generic postgres-credentials \
  --from-literal=POSTGRES_USER="$POSTGRES_USER" \
  --from-literal=POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
  --from-literal=KEYCLOAK_DB_PASSWORD="$KEYCLOAK_DB_PASSWORD" \
  --dry-run=client -o yaml \
| kubeseal \
  --cert "$SEALED_CONTROLLER_CERT_FILE" \
  --format yaml \
> gitops/platform/database/overlays/dev/postgres-secret.yaml
```

Then:

1. `git add gitops/platform/identity/overlays/dev/keycloak-secret.yaml gitops/platform/database/overlays/dev/postgres-secret.yaml`
2. commit + push

### 5. Wait for Argo CD + sync health (and find ALB DNS names)

After pushing the updated secrets, let Argo sync the platform workloads.

Argo CD may take a few minutes to detect drift and schedule reconciliation after a Git change (commonly ~5 minutes, depending on its polling / refresh settings).

Sync order is expected to be:

1. `platform-database` (wave `0`)
2. `platform-identity` (wave `1`)
3. `platform-ingress` (wave `2`)

Check health:

```bash
kubectl get applications -n argo
```

When `platform-ingress` is synced and healthy, extract the public ALB hostnames:

```bash
ARGO_HOST="$(kubectl -n argo get ingress platform-public-argo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
KEYCLOAK_HOST="$(kubectl -n identity get ingress platform-public-keycloak -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"

echo "Argo:     http://${ARGO_HOST}"
echo "Keycloak: http://${KEYCLOAK_HOST}"
```

### 6. Update Terraform OIDC URLs + apply again

Update `terraform/environments/dev/terraform.secrets.auto.tfvars`:

- `argocd_public_url = "http://${ARGO_HOST}"`
- `argocd_oidc_issuer = "http://${KEYCLOAK_HOST}/realms/agentic-cluster"`

Keep `argocd_oidc_client_secret` as the current placeholder value during this step; the real secret becomes available only after the Keycloak client is created (Step 7).

Then:

```bash
cd terraform/environments/dev
terraform apply
```

Terraform updates Argo CD Helm values, including:

- `configs.cm.url` (Argo server URL)
- `configs.cm.oidc.config.issuer`
- `configs.secret.extra["oidc.keycloak.clientSecret"]` (from `argocd_oidc_client_secret`)

### 7. Configure Keycloak realm + client + groups for Argo login

Log in to Keycloak:

- URL: `http://${KEYCLOAK_HOST}`
- Username/password: the values you used for `KEYCLOAK_ADMIN` / `KEYCLOAK_ADMIN_PASSWORD` when re-sealing `keycloak-secret.yaml`.

Do this inside Keycloak (realm = `agentic-cluster` because that’s what Argo OIDC issuer points to):

1. Create realm `agentic-cluster`.
2. Create groups:
   - `argocd-admin`
   - `argocd-readonly`
3. Create an initial user (or pick your own) and assign them to `argocd-admin` (for admin access in Argo).
4. Create an OpenID Connect **confidential** client named:
   - `argocd` (must match `argocd_oidc_client_id`)
5. Configure client:
   - `Root URL` / `Home URL` / `Admin URL`: `http://${ARGO_HOST}`
   - `Valid Redirect URIs`: `http://${ARGO_HOST}/auth/callback`
     - (if you see callback-related login issues, you may also need to add `http://${ARGO_HOST}/api/dex/callback` depending on the Argo CD version)
   - `Valid post logout redirect URIs`: `http://${ARGO_HOST}/login`
   - `Web origins`: `http://${ARGO_HOST}`
   - After the client is created, copy the generated “Client secret” value (this is what becomes `argocd_oidc_client_secret` in Terraform).
6. Update client scopes / token mappers to include group membership:
   - add/enable a mapper that puts groups into the token under the `groups` claim
   - ensure it is assigned as a default/always-included scope for that client *(your “include groups (default assigned type)” step)*.
7. Realm settings:
   - `Require SSL`: set to **None** (because this repo uses HTTP-only ALBs in dev; TLS ends at the ALB only when using HTTPS).

### 8. If you changed the Argo client secret, update Terraform and apply

Update Terraform with the exact Keycloak-generated client secret (this was unknown until you created the client in Step 7). Replace the placeholder in:

- `terraform/environments/dev/terraform.secrets.auto.tfvars` → `argocd_oidc_client_secret`

Then:

1. copy the Keycloak client secret value into `argocd_oidc_client_secret`
2. run `terraform apply` again

This is the last “secrets → terraform apply” step in your flow: it updates the Argo CD config secret that holds the Keycloak client secret.

### 9. Verify

1. Verify platform is healthy:
   - `kubectl -n argo get applications.argoproj.io`
2. Open Argo CD UI:
   - `http://${ARGO_HOST}`
3. Log in via Keycloak SSO and verify role mapping:
   - users in Keycloak group `argocd-admin` should get Argo role `admin`
   - users in Keycloak group `argocd-readonly` should get Argo role `readonly`

## Endpoints & credentials (summary)

|Item|Value / where stored|Notes|
|---|---|---|
|Argo CD URL|`terraform/environments/dev/terraform.secrets.auto.tfvars` → `argocd_public_url`|Example: `http://<ARGO_HOST>`|
|Keycloak URL|`http://${KEYCLOAK_HOST}` extracted from `kubectl get ingress`|Example: `http://<KEYCLOAK_HOST>`|
|Realm|`agentic-cluster`|Must exist in Keycloak (used in issuer URL)|
|Argo OIDC issuer|`terraform/environments/dev/terraform.secrets.auto.tfvars` → `argocd_oidc_issuer`|Example: `http://<KEYCLOAK_HOST>/realms/agentic-cluster`|
|Argo client|Keycloak client `argocd`|Must match `argocd_oidc_client_id`|
|Secrets in Git|`SealedSecret` YAMLs for `keycloak-credentials` / `postgres-credentials`|Re-seal per cluster|

> Redact actual secret values; point to the SealedSecret filenames and Key/Secret names instead.

## Troubleshooting

- SealedSecret decrypt failures
  - Symptom: `SealedSecret` resources exist but platform pods cannot read the underlying Secret.
  - Fix: re-seal `gitops/platform/identity/overlays/dev/keycloak-secret.yaml` and `gitops/platform/database/overlays/dev/postgres-secret.yaml` using the target cluster’s sealed-secrets controller public key, then commit + push.
- ALB hostnames not available yet
  - Fix: wait for `platform-ingress` to become healthy, then re-run the JSONPath extraction for `platform-public-argo` / `platform-public-keycloak`.
- Port-forwarding pain (OIDC mismatch)
  - If you port-forward Argo/Keycloak to `localhost`, the OIDC issuer URL and redirect URIs will no longer match what Keycloak issued tokens for.
  - Fix: prefer the real ALB DNS names extracted from ingress status; only use port-forwarding for debugging UI connectivity, not as the “source of truth” for OIDC.
- HTTPS/ACM vs HTTP
  - This repo’s dev config is HTTP-only: no ACM cert, ALB listener is 80 (`listen-ports: [{"HTTP": 80}]`).
  - If you switch to HTTPS, you likely need:
    - ACM cert + ingress TLS config
    - `argocd_oidc_tls_insecure_skip_verify = false`
    - Keycloak `Require SSL` not set to None.
