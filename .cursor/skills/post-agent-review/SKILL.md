---
name: post-agent-review
description: Structured review after an agent completes work — traces changes to PRD.md, runs IaC quality gates (fmt, validate, tflint), checks YAML polish, and produces a Pass/Partial/Fail report. Use when the user asks to review agent output, verify the job is done, sanity-check before commit, or after finishing a task.
---

# Post-agent review

Use this **after** an agent (or session) claims work is complete. Default to **read-only** verification first; apply fixes only if the user asks.

## 1. Intent and scope

- Infer **what was supposed to be done** from the latest user goal + recent edits (or ask one clarifying question if unclear).
- List **files touched** (`git status`, `git diff --stat`) and skim **full diff** for accidental churn.

## 2. Requirements trace (SRE challenge)

- Open `PRD.md` §4 (FR-1–FR-3), §5 (D1–D3), §10 (acceptance).
- Map each relevant requirement to **evidence** (paths). Mark **missing**, **stub**, or **doc-only**.

Optional: delegate to the **`challenge-verifier`** subagent for a second opinion on PRD coverage (readonly).

## 3. Terraform / Terragrunt

If `*.tf` or relevant `.hcl` changed:

- Follow skill **`terraform-tflint-format`**: `terraform fmt -recursive -check` (or fmt then review diff), `terraform validate` per root after `init -backend=false` where applicable, `tflint --init` + `tflint` from repo root or module path.
- Note any **skipped** checks (no Terraform yet, init blocked) explicitly in the report.

## 4. Kubernetes / Argo / Helm YAML

If `*.yaml` / `*.yml` changed:

- Follow skill **`kubernetes-yaml-polish`** (format consistency, no tabs, trailing whitespace).
- Quick sanity: valid structure, namespaces (`argo`, `database`, `identity` when applicable), no obvious secret literals in Git.

## 5. Docs and deliverables

- If the challenge docs exist: D1/D2/D3 sections present, steps **ordered**, placeholders for endpoints/credentials called out.
- README or runbook matches **actual** repo layout.

## 6. Report format

Produce:

| Area            | Status (pass/partial/fail) | Notes + paths |
|-----------------|----------------------------|---------------|
| PRD / trace     |                            |               |
| Terraform gates |                            |               |
| YAML / GitOps   |                            |               |
| Docs            |                            |               |

Finish with **blockers** (must fix), **nits** (should fix), and **optional** improvements.

## 7. Refactor discipline

If recommending changes, follow skill **`iac-refactor-polish`**: smallest diff, no scope creep.
