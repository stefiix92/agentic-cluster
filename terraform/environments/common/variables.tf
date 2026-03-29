variable "environment_name" {
  type        = string
  description = "Name of the environment."
}

variable "aws_region" {
  type        = string
  default     = "eu-central-1"
  description = "AWS region for this stack."
}

variable "aws_profile" {
  type        = string
  default     = null
  description = "Optional config profile (e.g. from `aws sso login --profile foo`). Null = default credential chain."
}

variable "aws_role_arn" {
  type        = string
  default     = null
  description = "Optional IAM role for Terraform to assume on top of your base credentials (sts:AssumeRole). Leave null for keys/profile only, or for CI OIDC using env vars (see providers.tf)."
}

variable "name_prefix" {
  type        = string
  default     = "agentic-cluster"
  description = "Prefix for VPC and other resource names."
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "IPv4 CIDR for the VPC module."
}

variable "vpc_az_count" {
  type        = number
  default     = 3
  description = "Number of AZs / subnet pairs (2–4; 3 is typical for HA)."

  validation {
    condition     = var.vpc_az_count >= 2 && var.vpc_az_count <= 4
    error_message = "vpc_az_count must be between 2 and 4."
  }
}

variable "vpc_single_nat_gateway" {
  type        = bool
  default     = true
  description = "Use one NAT Gateway for all private subnets (cheaper). Set false for NAT per AZ."
}

variable "common_tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to VPC and EKS resources."
}

variable "cluster_name" {
  type        = string
  default     = null
  description = "Override EKS / subnet tag cluster name; default is {name_prefix}-{environment_name}."
}

variable "eks_kubernetes_version" {
  type        = string
  default     = "1.35"
  description = "EKS control plane and node group version."
}

variable "eks_cluster_endpoint_private_access" {
  type        = bool
  default     = true
  description = "Kubernetes API reachable from inside the VPC."
}

variable "eks_cluster_endpoint_public_access" {
  type        = bool
  default     = true
  description = "Kubernetes API exposed on the public endpoint. If true, set kubernetes_api_allowed_cidrs (e.g. your /32)."
}

variable "kubernetes_api_allowed_cidrs" {
  type        = list(string)
  default     = []
  description = "CIDRs allowed to use the **public** Kubernetes API endpoint, e.g. [\"203.0.113.10/32\"]. Must be non-empty when eks_cluster_endpoint_public_access is true. Use [] when the public endpoint is disabled (VPC-only API)."
}

variable "eks_node_capacity_type" {
  type        = string
  default     = "SPOT"
  description = "EKS managed node group: ON_DEMAND or SPOT."
}

variable "eks_node_instance_types" {
  type        = list(string)
  default     = ["t3.medium"]
  description = "Instance types for the default managed node group."
}

variable "eks_node_desired_size" {
  type    = number
  default = 2
}

variable "eks_node_min_size" {
  type    = number
  default = 1
}

variable "eks_node_max_size" {
  type    = number
  default = 4
}

variable "sealed_secrets_helm_chart_version" {
  type        = string
  default     = "2.18.4"
  description = "bitnami-labs sealed-secrets Helm chart (https://github.com/bitnami-labs/sealed-secrets/tree/main/helm-chart)."
}

variable "sealed_secrets_namespace" {
  type        = string
  default     = "kube-system"
  description = "Namespace for the sealed-secrets controller (kube-system is the chart default)."
}

variable "sealed_secrets_create_namespace" {
  type        = bool
  default     = false
  description = "Create the sealed-secrets namespace if it doesn't exist."
}

variable "argocd_helm_chart_version" {
  type        = string
  default     = "9.4.17"
  description = "argo-helm chart version for argo-cd (https://github.com/argoproj/argo-helm/releases)."
}

variable "argocd_public_url" {
  type        = string
  default     = "http://localhost:8081"
  description = "Argo CD external URL (no trailing slash). After HTTP ALB ingress sync: http://<argo ingress hostname>."
}

variable "argocd_oidc_issuer" {
  type        = string
  default     = "http://localhost:8080/realms/agentic-cluster"
  description = "OIDC issuer URL. After Keycloak ingress sync: http://<keycloak ingress hostname>/realms/<realm>."
}

variable "aws_load_balancer_controller_chart_version" {
  type        = string
  default     = "3.1.0"
  description = "aws-load-balancer-controller Helm chart (https://github.com/aws/eks-charts)."
}

variable "argocd_oidc_client_id" {
  type        = string
  default     = "argocd"
  description = "OIDC client ID registered with the IdP (must match Keycloak client)."
}

variable "argocd_oidc_tls_insecure_skip_verify" {
  type        = bool
  default     = true
  description = "Dev HTTP OIDC / lab IdPs: set oidc.tls.insecure.skip.verify on Argo CD (disable for HTTPS+trusted certs)."
}

variable "argocd_oidc_client_secret" {
  type        = string
  sensitive   = true
  default     = "replace-when-keycloak-confidential-client-exists"
  description = "OIDC confidential client secret → argocd-secret key oidc.keycloak.clientSecret. Override in tfvars or TF_VAR_ for real clusters."
}

variable "argocd_gitops_repo_url" {
  type        = string
  default     = "https://github.com/stefiix92/agentic-cluster.git"
  description = "Git repo URL for Argo CD app-of-apps (must match child Application manifests in Git)."
}

variable "argocd_gitops_target_revision" {
  type        = string
  default     = "HEAD"
  description = "Revision for the root Application (branch, tag, or commit SHA)."
}

variable "argocd_gitops_applications_path" {
  type        = string
  default     = null
  description = "Repo path to env-scoped Application YAMLs (default: gitops/argocd/applications/{environment_name})."
}
