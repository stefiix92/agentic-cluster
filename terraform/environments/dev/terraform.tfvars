aws_region       = "eu-central-1"
environment_name = "dev"
common_tags      = { Environment = "dev" }

name_prefix            = "agentic-cluster"
vpc_cidr               = "10.0.0.0/16"
vpc_az_count           = 2
vpc_single_nat_gateway = true

eks_node_instance_types = ["t3.medium"]
eks_node_desired_size   = 2
eks_node_min_size       = 2
eks_node_max_size       = 2

# Optional: sts:AssumeRole on top of those base creds
# aws_role_arn = "arn:aws:iam::123456789012:role/TerraformExecutor"

# CI OIDC: set AWS_ROLE_ARN + AWS_WEB_IDENTITY_TOKEN_FILE in the job env (or use configure-aws-credentials);
# leave aws_role_arn unset here to avoid double-assume.

