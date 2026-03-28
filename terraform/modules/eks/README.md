# Module: `eks`

Creates an **EKS** control plane, a **managed node group** in **private** subnets, and an **OIDC provider** for IRSA.

## Kubernetes API network access

| Mode | Settings |
|------|-----------|
| **Public API locked to your IP(s)** | `cluster_endpoint_public_access = true`, `cluster_endpoint_private_access = true`, `kubernetes_api_public_access_cidrs = ["x.x.x.x/32"]` |
| **VPC-only API** (no public endpoint) | `cluster_endpoint_public_access = false`, `cluster_endpoint_private_access = true` — use `kubectl` from a host in the VPC, VPN, or SSM port-forward |

When the public endpoint is on, **this module requires** a non-empty `kubernetes_api_public_access_cidrs` list (no default `0.0.0.0/0`).

## Inputs (summary)

See `variables.tf`. Notable: `kubernetes_version`, node group sizing, and tags.
