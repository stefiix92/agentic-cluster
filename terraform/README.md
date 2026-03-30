# Terraform (FR-1)

Declarative **AWS + Kubernetes control plane** baseline per PRD.

| Path | Role |
| ------ | ------ |
| `modules/` | Reusable building blocks (VPC, EKS, add-ons, …) |
| `environments/common/` | Shared root `.tf` files symlinked by each env |
| `environments/<env>/` | Per-env dir: symlinks → `common/`, plus `*.tfvars`, backend config, etc. |

**Terragrunt:** If you use it, add a `terragrunt/` tree at repo root and keep shared modules here under `modules/`.

## AWS credentials (Terraform AWS provider)

The provider uses the **standard AWS SDK chain** unless you set optional role / OIDC variables in `variables.tf`:

| Method | Typical use | Terraform |
| -------- | ------------- | ----------- |
| **Access keys in env** | Local / quick lab | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, optional `AWS_SESSION_TOKEN` |
| **`~/.aws/credentials`** | Local | Default or named **profile**; set `aws_profile` or `AWS_PROFILE` |
| **IAM Identity Center (SSO)** | Human users | `aws sso login` then `aws_profile = "..."` or `AWS_PROFILE` |
| **`assume_role`** | Cross-account, hub-spoke | Set `aws_role_arn` (+ optional `aws_assume_role_external_id`); base creds must allow `sts:AssumeRole` |
| **Web identity (OIDC)** | CI without long-lived keys | Set **`AWS_ROLE_ARN`** + **`AWS_WEB_IDENTITY_TOKEN_FILE`** in the environment (SDK default chain); or **`configure-aws-credentials`** and temporary keys — no extra Terraform variables |
| **Pre‑assumed env from CI action** | GitHub `configure-aws-credentials` | Often exports temp keys; leave OIDC variables null — provider uses env |

Other enterprise patterns (not wired in code here): **SAML SSO**, **Workload Identity Federation** with custom token exchange, **EC2 instance profile** / **ECS task role** when Terraform runs on AWS.

See `environments/dev/terraform.secrets.auto.tfvars.example` and `common/providers.tf` comments.

## Bootstrap (Helm + root app-of-apps)

The **Helm** provider connects to the **same EKS API** as `kubectl`, using `data.aws_eks_cluster` + `data.aws_eks_cluster_auth` in `environments/common/data.tf`.

In `terraform/environments/common/main.tf`, Terraform installs these Helm releases before GitOps sync:

- `helm_release.sealed_secrets` (`sealed-secrets` controller)
- `helm_release.aws_load_balancer_controller` (`aws-load-balancer-controller` for the ALB ingresses)
- `helm_release.argocd` (Argo CD into namespace **`argo`**)

`helm_release.argocd` merges `environments/common/argocd-helm-values.yaml.tftpl` (OIDC URL/issuer/client) and injects the Keycloak client secret into `configs.secret.extra["oidc.keycloak.clientSecret"]`.

Finally, Terraform creates the `root-platform` app-of-apps `Application` via `kubernetes_manifest.argocd_root_application`, pointing at `gitops/argocd/applications/${var.environment_name}` and including `*.yaml` (excluding `root-platform.yaml`).

IAM running Terraform needs **`eks:DescribeCluster`** (and token flow uses the same principal as AWS CLI `aws eks get-token`).

After the first successful `terraform apply`, you can generate/update kubeconfig locally with:

- `terraform/environments/connect_to_eks.sh --env dev`

## Destroy order (Helm vs EKS)

`helm_release.argocd` **depends on** `module.eks`, so on **`terraform destroy`** Terraform removes the Helm release **first** (while the API still answers), then **EKS**, then **VPC**. You do not need a special flag for normal destroys.

If something breaks mid-destroy, run **`terraform destroy -target=helm_release.argocd`** once, then **`terraform destroy`** for the rest.
