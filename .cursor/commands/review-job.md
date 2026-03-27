# Review job (post-agent)

Run a **post-agent review** of the current workspace.

1. Read and execute the checklist in `.cursor/skills/post-agent-review/SKILL.md` end-to-end.
2. Use **read-only** mode first: inspect `git` state, read files, run non-destructive checks (`fmt -check`, `validate`, `tflint`, yamllint/prettier if configured). Do **not** modify files unless I explicitly ask you to fix issues.
3. Cross-check outcomes against `PRD.md` (FR-1–FR-3, D1–D3, §10 acceptance). Optionally invoke the **`challenge-verifier`** subagent for a focused PRD gap analysis, then merge findings into one report.
4. End with: **Pass / Partial / Fail** per area, **evidence paths**, **blockers**, and **next actions** (ordered).

If Terraform or YAML quality tools are missing from PATH, say so and still complete the trace + diff review.
