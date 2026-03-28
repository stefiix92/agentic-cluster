variable "cluster_name" {
  type        = string
  description = "EKS cluster name (must match DNS-1123 subset)."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnets for worker nodes and cluster ENIs (multi-AZ)."
}

variable "kubernetes_version" {
  type        = string
  default     = "1.31"
  description = "Control plane and managed node group Kubernetes version."
}

variable "cluster_endpoint_private_access" {
  type        = bool
  default     = true
  description = "Allow Kubernetes API access from within the VPC (e.g. nodes, VPN, bastion)."
}

variable "cluster_endpoint_public_access" {
  type        = bool
  default     = true
  description = "Expose the Kubernetes API on the public internet. If true, you must set kubernetes_api_public_access_cidrs (no open 0.0.0.0/0 in this module)."
}

variable "kubernetes_api_public_access_cidrs" {
  type        = list(string)
  default     = []
  description = "CIDRs allowed to reach the public API endpoint (e.g. [\"203.0.113.10/32\"] for your home IP). Ignored when cluster_endpoint_public_access is false."
}

variable "node_capacity_type" {
  type        = string
  default     = "SPOT"
  description = "Managed node group capacity: ON_DEMAND or SPOT (same instance_types; SPOT uses EC2 Spot)."
}

variable "node_instance_types" {
  type        = list(string)
  default     = ["t3.medium"]
  description = "Instance types for the default managed node group."
}

variable "node_desired_size" {
  type        = number
  default     = 2
  description = "Desired worker count."
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 4
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to EKS resources."
}
