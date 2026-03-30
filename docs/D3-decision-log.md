# D3 — Decision log & production readiness

---

## Quick summary (dev-first choices)

|Decision|Chosen|Why it was “good enough” for dev|
|---|---|---|
|EKS AZ count (`az_count`)|`2`|Minimum viable HA for dev/personal while lowering cost|
|EKS API reachability|Public|Avoid VPN/bastion complexity; faster iteration|
|Public exposure method for ArgoCD + Keycloak|ALB (HTTP)|Fastest path; skip ACM/domains for assignment speed|
|Secrets approach|Sealed Secrets|GitOps-friendly; avoids adding heavier secret infra|
|GitHub → ArgoCD repo access|Repo is public|Avoid deploy keys/PATs and secret sprawl|
|GitOps bootstrap / root app placement|Root app deployed by Terraform|Ensures root app exists during cluster creation|
|Telemetry/metrics|Omitted|Assignment didn’t require it; debugging via kubectl was enough|

---

## Decisions

### Decision: Pick `az_count=2` for dev/personal

- **Context / constraints:** Dev/personal EKS cluster; minimize spend while still meeting a basic HA bar.
- **Options considered:** Higher AZ count (more resilience, higher cost) vs minimum viable AZ count.
- **Chosen:** `az_count = 2` (minimum for EKS in this setup).
- **Why:** For dev and personal use, 2 AZs is sufficient to reduce risk versus a single-AZ deployment, while keeping costs down.
- **If this were production:** Use an AZ count aligned to availability requirements (typically 3+), then apply explicit cost caps/alerts; validate node group capacity per AZ and rehearse AZ-failure scenarios (including cluster-autoscaler behavior and PodDisruptionBudgets).

---

### Decision: Make the EKS API publicly reachable

- **Context / constraints:** Need a working, developer-friendly bootstrap path; private endpoint adds networking prerequisites (VPN/bastion) that cost time and money.
- **Options considered:** Public EKS API vs private EKS API (requires VPN or bastion access from your environment).
- **Chosen:** Public endpoint.
- **Why:** Public access is more convenient for dev/personal usage; private would improve security but would require extra infrastructure (VPN-in-VPC or bastion host), increasing complexity and cost.
- **If this were production:** Prefer a private endpoint (or hybrid) with tightly scoped network access (VPC endpoints + corporate VPN/bastion with session auditing), enforce IAM least-privilege for cluster access, and add alerting for unexpected API access patterns.

---

### Decision: Expose ArgoCD + Keycloak via ALB (skip ACM/domains)

- **Context / constraints:** Fast completion path for the assignment; dev environment; accept additional cost because speed matters more than production-grade routing for now. The OIDC flow needs a browser-reachable endpoint, so cluster-local service DNS between ArgoCD and Keycloak would not have been sufficient.
- **Options considered:** ALB with HTTP vs ACM certificates + custom domains; alternatives like Traefik + your own domain mapped to the ALB IP.
- **Chosen:** Use ALB-based ingress for public access to ArgoCD and Keycloak; avoid ACM certificates and domains for dev speed.
- **Why:** ALBs were the fastest way to get the job done and avoided adding/maintaining certificate and domain plumbing. Traefik + domain mapping didn’t match the assignment requirements and added “extra system” overhead.
- **If this were production:** Terminate TLS with ACM + managed certificates, enforce HTTPS-only listeners, implement strict ingress routing and WAF/Shield policies where appropriate, and remove any temporary “dev shortcuts” (like HTTP-only settings). Also add SLOs for ingress latency/error-rate and define blast-radius for ingress controller changes.

---

### Decision: Use Sealed Secrets to keep secrets GitOps-friendly

- **Context / constraints:** Secrets must live alongside infrastructure and GitOps manifests, without turning the repo into a plaintext-secret vault.
- **Options considered:** External Secrets Operator / cloud secret managers vs HashiCorp Vault vs Sealed Secrets.
- **Chosen:** Sealed Secrets.
- **Why:** It’s simpler and more lightweight than standing up heavier secret-management systems while still keeping secrets encrypted at rest in the GitOps repository.
- **If this were production:** Use a rotation strategy (keys/certs and sealed secret regeneration), define operational runbooks for controller cert rotation, and consider moving toward a dedicated secret manager if you need richer audit trails, fine-grained access policies, or automated secret rotation workflows. The strongest AWS production alternative would likely be External Secrets Operator backed by AWS Secrets Manager or SSM Parameter Store.

---

### Decision: Allow ArgoCD to read from a public GitHub repo (no deploy key/PAT)

- **Context / constraints:** Keep GitHub integration simple and avoid storing additional credentials in Terraform.
- **Options considered:** Public repo access (no credentials) vs private repo access (requires deploy key or PAT stored as Terraform secret value, then wired into the ArgoCD Helm chart).
- **Chosen:** Public repo, so ArgoCD can read resources without deploy keys / PATs.
- **Why:** Repo is public; requiring a deploy key/PAT would add secret-management and credential wiring complexity.
- **If this were production:** Prefer private repo + scoped credentials (fine-grained PAT or deploy key with tight permissions) stored in a proper secret manager; avoid embedding secrets in Terraform state. In production I would also combine a private repository with branch protection, required reviews, signed commits and ArgoCD sync restrictions to reduce the blast radius of a bad commit. Limit blast radius with least-privilege and rotate credentials on a schedule.

---

### Decision: Deploy the ArgoCD “root application” from the Terraform repo

- **Context / constraints:** Cluster bootstrap must be self-contained; ArgoCD root app should exist without a manual kick-off step.
- **Options considered:** Keep root application outside Terraform and apply manually vs ensure root app is applied automatically during cluster creation.
- **Chosen:** Root app application lives in the Terraform repo and is applied automatically during cluster creation.
- **Why:** This makes bootstrap deterministic: Terraform creates the platform releases and ensures the root App exists so ArgoCD can reconcile the rest of GitOps workloads.
- **If this were production:** Replace “Terraform applies root app” with a more explicit bootstrap flow (out-of-band apply once per environment, then GitOps owns steady-state). Add guardrails so bootstrap changes are audited and idempotent, and ensure sync ordering (waves) is enforced with health checks.

---

### Decision: Omit telemetry/metrics for this assignment/dev

- **Context / constraints:** The assignment didn’t require telemetry/metrics; dev iteration speed and debuggability via direct Kubernetes tooling were prioritized.
- **Options considered:** Add metrics/telemetry (extra components and configuration) vs omit for now.
- **Chosen:** Omit telemetry and metrics.
- **Why:** For the scope of the assignment, operational debugging through `kubectl`, ArgoCD and pod logs was sufficient. Adding a full observability stack would have increased cost and complexity without materially improving the evaluation goals.
- **If this were production:** Enable telemetry (logs/metrics/traces) with an opinionated baseline (e.g., Prometheus/Grafana and log aggregation) and define alert thresholds tied to SLOs. Establish retention policies, on-call runbooks, and verify dashboards during acceptance testing.
