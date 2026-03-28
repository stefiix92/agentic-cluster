variable "name_prefix" {
  type        = string
  description = "Prefix for resource Name tags (e.g. project or env key)."
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "IPv4 CIDR for the VPC."
}

variable "az_count" {
  type        = number
  default     = 3
  description = "How many AZs to spread subnets across (one public + one private per AZ). Three is the usual HA target for Kubernetes; four is a hard cap for this module’s /24 layout."

  validation {
    condition     = var.az_count >= 1 && var.az_count <= 4
    error_message = "az_count must be between 1 and 4."
  }
}

variable "single_nat_gateway" {
  type        = bool
  default     = true
  description = "If true, one NAT Gateway shared by all private subnets (cheaper). If false, one NAT per AZ (higher availability)."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Extra tags applied to all resources."
}

variable "eks_cluster_name" {
  type        = string
  default     = null
  description = "If set, adds kubernetes.io/cluster/<name> tags on subnets for EKS load balancer discovery."
}
