# D1 — AI usage log

## Tools & agents

| Tool / agent / skill | Used for |
|----------------------|----------|
| PRD.md created from challenge PDF (Anthropic Sonnet) | Draft the initial `PRD.md` based on the challenge spec you received as a PDF, using Anthropic's Sonnet model |
| Cursor core agents (repo bootstrapped from day 1) | Define the "agentic flow" baseline and keep prompts/tooling consistent from the start of the repo |
| Cursor `Auto` model execution | All agent prompts were executed via Cursor's `Auto` model routing (Cursor decides which model to use behind the scenes) |
| `.cursor/skills/post-agent-review/SKILL.md` | Enforce a structured "post-agent review" loop: trace to `PRD.md`, run IaC quality gates, sanity-check YAML, and output Pass/Partial/Fail |
| `.cursor/skills/iac-refactor-polish/SKILL.md` | Keep refactors minimal/scope-disciplined and run IaC + YAML polish after meaningful changes |
| `.cursor/skills/kubernetes-yaml-polish/SKILL.md` | Normalize Kubernetes/Helm/Argo YAML formatting while avoiding accidental semantic drift |
| `.cursor/skills/terraform-tflint-format/SKILL.md` | Run `terraform fmt` + `terraform validate` + `tflint` loops before calling work "done" |
| `.cursor/commands/review-job.md` | A single command wrapper to run the "review job" / checklist workflow after an agent claims completion |

## Overall satisfaction

Overall satisfaction was very good.

This assignment was a good practice run to bootstrap the core of the repo (ArgoCD + Terraform) from scratch using an agentic approach, and it helped me adapt my style of work to be as agentic as possible.

In other words: I'm switching from "AI Assistant" to an agentic flow where the repo encodes who agents are, which skills they use, and what "done" means.

## What helped

- Constraining the workflow via skills/commands made outcomes more reviewable (especially the "quality gate" mentality after edits).
- The agentic bootstrapping path worked well for early-stage GitOps + IaC setup: iterative generation -> structured review -> small-scope tightening.

## What misled or wasted time

- Terraform planning/validation misses:
  - VPC `az_count` validation: the agent assumed `az_count` default `6`; you manually lowered it to `4`.
  - EKS node capacity pricing: the agent didn't suggest `spot` instances; you had to explicitly steer the trade-off (production prefers `ON_DEMAND`, spot OK for dev).
  - Storage integration: the agent didn't suggest `ebs-csi-driver`; you discovered it when PVCs weren't being created (even though `gp2` storage class exists by default).
- GitOps/ArgoCD bootstrapping misfit:
  - The agent suggested a manual `kubectl apply` kick-off flow (root platform application living under `gitops/` plus an initial apply step).
  - You found the manual step wasn't useful, and moved the root application into the Terraform `terraform/argocd` Helm release so it gets applied automatically during cluster creation.
- Secrets/security hygiene:
  - The agent proposed plain text secrets in the repo.
  - You had to steer it toward `sealed secrets` and manually generate the values.
- Keycloak and auth correctness gaps:
  - Keycloak groups scope wasn't included by default; you had to add it manually after noticing group assignment wasn't reflecting properly (agent could have surfaced this earlier).
  - Port-forwarding for dev didn't fully match the real login path: the agent convinced you it would be sufficient, but login behavior differs between requests made in the user browser vs inside the ArgoCD pod.
  - Fix required adding ALB ingresses for the correct request path.

## Not trusted without my review

- terraform apply was not trusted without my review, had to review the changes and approve them manually
- sealed secrets generation was not trusted
