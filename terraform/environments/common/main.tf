locals {
  cluster_name = coalesce(var.cluster_name, "${var.name_prefix}-${var.environment_name}")

  argocd_namespace = "argo"
  argocd_root_application = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name       = "root-platform"
      namespace  = local.argocd_namespace
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/stefiix92/agentic-cluster.git"
        targetRevision = "HEAD"
        path           = format("gitops/argocd/applications/%s", var.environment_name)
        directory = {
          include = "*.yaml"
          exclude = "root-platform.yaml"
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = local.argocd_namespace
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
      }
    }
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name_prefix        = var.name_prefix
  vpc_cidr           = var.vpc_cidr
  az_count           = var.vpc_az_count
  single_nat_gateway = var.vpc_single_nat_gateway
  tags               = var.common_tags
  eks_cluster_name   = local.cluster_name
}

module "eks" {
  source = "../../modules/eks"

  cluster_name       = local.cluster_name
  private_subnet_ids = module.vpc.private_subnet_ids

  kubernetes_version = var.eks_kubernetes_version

  cluster_endpoint_private_access    = var.eks_cluster_endpoint_private_access
  cluster_endpoint_public_access     = var.eks_cluster_endpoint_public_access
  kubernetes_api_public_access_cidrs = var.kubernetes_api_allowed_cidrs

  node_capacity_type  = var.eks_node_capacity_type
  node_instance_types = var.eks_node_instance_types
  node_desired_size   = var.eks_node_desired_size
  node_min_size       = var.eks_node_min_size
  node_max_size       = var.eks_node_max_size

  tags = var.common_tags
}

resource "helm_release" "sealed_secrets" {
  name             = "sealed-secrets"
  chart            = "sealed-secrets"
  repository       = "https://bitnami-labs.github.io/sealed-secrets"
  version          = var.sealed_secrets_helm_chart_version
  namespace        = var.sealed_secrets_namespace
  create_namespace = var.sealed_secrets_create_namespace

  depends_on = [module.eks]
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  chart      = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  version    = var.aws_load_balancer_controller_chart_version
  namespace  = "kube-system"

  values = [yamlencode({
    clusterName = module.eks.cluster_name
    region      = var.aws_region
    vpcId       = module.vpc.vpc_id
    serviceAccount = {
      create = true
      annotations = {
        "eks.amazonaws.com/role-arn" = module.eks.aws_load_balancer_controller_role_arn
      }
    }
    enableShield = false
  })]

  depends_on = [module.eks]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  chart            = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  version          = var.argocd_helm_chart_version
  namespace        = local.argocd_namespace
  create_namespace = true

  values = [
    templatefile("${path.module}/../common/argocd-helm-values.yaml.tftpl", {
      argocd_public_url                    = var.argocd_public_url
      argocd_oidc_issuer                   = var.argocd_oidc_issuer
      argocd_oidc_client_id                = var.argocd_oidc_client_id
      argocd_oidc_tls_insecure_skip_verify = var.argocd_oidc_tls_insecure_skip_verify ? "true" : "false"
    }),
    yamlencode({
      configs = {
        secret = {
          extra = {
            "oidc.keycloak.clientSecret" = sensitive(var.argocd_oidc_client_secret)
          }
        }
      }
    })
  ]

  depends_on = [module.eks, helm_release.sealed_secrets, helm_release.aws_load_balancer_controller]
}

resource "kubernetes_manifest" "argocd_root_application" {
  manifest   = local.argocd_root_application
  depends_on = [helm_release.argocd]
}
