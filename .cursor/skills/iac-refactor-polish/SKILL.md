---
name: iac-refactor-polish
description: Refactors and polishes IaC and GitOps changes with minimal scope, consistent naming, and post-change quality gates (Terraform fmt/validate/tflint, YAML polish). Use when the user asks to refactor, clean up, polish, reduce duplication, or prepare a submission-quality diff without scope creep.
---

# IaC refactor and polish (disciplined)

## Rules (non-negotiable)

1. **Smallest diff** that achieves the goal — no drive-by renames, no unrelated file touches.
2. **Match existing** module layout, naming (`snake_case` in HCL, repo’s YAML style), and comment density.
3. **Extract variables/locals** only when it removes duplication or clarifies env-specific knobs — not for one-off literals.
4. **Preserve behaviour** unless the user explicitly asked for a behavioural change; document any intentional drift in the decision log.

## Refactor checklist

- [ ] Identify **one** objective (e.g. “dedupe subnet IDs”, “single Argo app template”).
- [ ] Introduce **backward-compatible** variables where external callers exist.
- [ ] Run **Terraform quality** after HCL edits: load skill `terraform-tflint-format` and run fmt → validate → tflint.
- [ ] Run **YAML polish** after manifest edits: load skill `kubernetes-yaml-polish`.
- [ ] Re-read the diff: every hunk should be **justifiable** in a PR or decision log line.

## Polish without refactor

- Fix formatting, lint, typos in **touched files only**.
- Prefer **end-of-task** cleanup: run formatters once, then review the diff for accidental churn.

## Anti-patterns

- Rewriting entire directories “for consistency” in one go without a ticket-level goal.
- Disabling TFLint or linters broadly instead of fixing or narrowly suppressing with a comment.
- Mixing **functional** changes with **cosmetic** reformats in the same commit when avoidable — split if the user cares about reviewability.
