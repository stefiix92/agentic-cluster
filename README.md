# agentic-cluster

Reference AWS platform: **EKS + Argo CD (GitOps) + PostgreSQL + Keycloak + Argo OIDC**. Requirements: [PRD.md](./PRD.md).

## Layout

| Path | Purpose |
|------|---------|
| [docs/](./docs/) | D1–D3 deliverables + runbook |
| [terraform/](./terraform/) | FR-1 — AWS / cluster baseline; shared roots in `terraform/environments/common/`, envs symlink + tfvars |
| [gitops/](./gitops/) | FR-2 / FR-3 — Argo CD bootstrap + platform apps (`argo`, `database`, `identity`) |
| [terragrunt/](./terragrunt/) | Optional Terragrunt roots |
| [scripts/](./scripts/) | Optional helpers |
| [.cursor/](./.cursor/) | Agent / skill / command definitions for implementation |

## Quick links

- Rebuild from zero → `docs/D2-reproducibility-guide.md`  
- Design rationale → `docs/D3-decision-log.md`  
- AI usage → `docs/D1-ai-usage-log.md`  
