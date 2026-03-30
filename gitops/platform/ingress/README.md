# Platform: Ingress / ALB (`argo` + `identity`)

Purpose: expose **public HTTP** endpoints through AWS ALB ingresses using the **aws-load-balancer-controller** installed by Terraform.

Layout: **`base/`** + **`overlays/<env>/`**. Argo CD points at `gitops/platform/ingress/overlays/<env>`.

## Current (dev) behavior

For `dev/`, `overlays/dev/kustomization.yaml` references the base resources as-is.

Base ingresses:

- `base/ingress-argocd.yaml`
  - Ingress name: `platform-public-argo`
  - Namespace: `argo`
  - Routes `/` (Prefix) to service `argocd-server:80`
- `base/ingress-keycloak.yaml`
  - Ingress name: `platform-public-keycloak`
  - Namespace: `identity`
  - Routes `/` (Prefix) to service `keycloak:8080`

Both ingresses use `ingressClassName: alb` and share ALB annotations for:

- `alb.ingress.kubernetes.io/scheme: internet-facing`
- `alb.ingress.kubernetes.io/target-type: ip`
- group name separation (`platform-public-argo` vs `platform-public-keycloak`) so both ALBs don’t get merged
- `alb.ingress.kubernetes.io/inbound-cidrs: 0.0.0.0/0` (dev)

## Sync ordering

`gitops/argocd/applications/dev/platform-ingress.yaml` sync-wave is `2`, so the platform namespaces + apps are applied before the ALBs.
