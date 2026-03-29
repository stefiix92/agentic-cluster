output "vpc_id" {
  description = "VPC ID from the vpc module."
  value       = module.vpc.vpc_id
}

output "vpc_public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.vpc.public_subnet_ids
}

output "vpc_private_subnet_ids" {
  description = "Private subnet IDs (EKS nodes, internal workloads)."
  value       = module.vpc.private_subnet_ids
}

output "eks_cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Kubernetes API endpoint."
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 cluster CA (for kubeconfig)."
  value       = module.eks.cluster_certificate_authority_data
}

output "eks_oidc_issuer_url" {
  description = "OIDC issuer URL for IRSA."
  value       = module.eks.cluster_oidc_issuer_url
}

output "eks_oidc_provider_arn" {
  description = "IAM OIDC provider ARN."
  value       = module.eks.oidc_provider_arn
}

output "public_http_alb_setup_hint" {
  description = "After platform-ingress syncs: `kubectl get ingress -A` — set argocd_public_url / argocd_oidc_issuer (http://) to those hostnames and terraform apply."
  value       = "HTTP-only ALB; no ACM. Two ingresses = two ELB DNS names."
}
