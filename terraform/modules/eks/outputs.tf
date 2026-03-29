output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_arn" {
  description = "EKS cluster ARN."
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded CA cert for kubeconfig."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL (for IRSA and IAM roles)."
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "IAM OIDC provider ARN for IRSA."
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "node_group_name" {
  description = "Default managed node group name."
  value       = aws_eks_node_group.this.node_group_name
}

output "ebs_csi_controller_role_arn" {
  description = "IAM role ARN passed to the aws-ebs-csi-driver EKS add-on (IRSA)."
  value       = aws_iam_role.ebs_csi.arn
}

output "aws_load_balancer_controller_role_arn" {
  description = "IAM role ARN for aws-load-balancer-controller (IRSA)."
  value       = aws_iam_role.aws_load_balancer_controller.arn
}
