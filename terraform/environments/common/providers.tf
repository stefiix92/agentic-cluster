# Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
#
# Credential chain: env keys, ~/.aws, profile, instance metadata — then optional AssumeRole below.
#
# OIDC / GitHub Actions: prefer the SDK env vars (no Terraform variables):
#   AWS_ROLE_ARN, AWS_WEB_IDENTITY_TOKEN_FILE
# or use aws-actions/configure-aws-credentials so Terraform only sees temporary keys.
#
# Use aws_role_arn only when you already have base creds and want Terraform to call sts:AssumeRole explicitly.

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  dynamic "assume_role" {
    for_each = var.aws_role_arn != null ? [1] : []
    content {
      role_arn     = var.aws_role_arn
      session_name = "terraform"
    }
  }
  default_tags {
    tags = {
      Environment = var.environment_name
      Project     = "agentic-cluster"
      ManagedBy   = "Terraform"
    }
  }
}

# Same EKS auth as `aws eks update-kubeconfig` (IAM: eks:DescribeCluster, etc.).
provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

# For `kubernetes_manifest` and other kubernetes_* resources; keep in sync with Helm block above.
provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}
