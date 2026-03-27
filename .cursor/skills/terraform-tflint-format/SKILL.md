---
name: terraform-tflint-format
description: Formats Terraform with terraform fmt, validates with terraform validate, and lints with TFLint (AWS ruleset). Use when editing .tf, .tfvars, Terragrunt .hcl tied to Terraform, before commits, or when the user mentions tflint, terraform fmt, or HCL polish.
---

# Terraform format, validate, and TFLint

## Preconditions

- `terraform` ≥ 1.5 installed (match `required_version` in code when present).
- `tflint` installed: https://github.com/terraform-linters/tflint/releases
- From a **module/root** directory: `terraform init` (use `-backend=false` for local checks without remote state).

## Mandatory loop after substantive HCL changes

Run in **each** Terraform root (or use `--recursive` where supported):

1. **Format (write)**  
   `terraform fmt -recursive`  
   Optional CI gate: `terraform fmt -recursive -check -diff`

2. **Validate**  
   `terraform validate`

3. **TFLint**  
   From repo root (uses `.tflint.hcl`):  
   `tflint --init`  
   `tflint .` **or** `tflint <terraform-module-path>` (CLI accepts directories).  
   Repeat for each Terraform root if the repo has multiple disjoint stacks and a single run does not cover them.

Do **not** treat “no errors” as enough if `fmt -check` would fail — formatting is part of quality.

## Terragrunt

- Run `terragrunt hcl fmt` on `.hcl` files when the project uses Terragrunt.  
- Then run `terraform fmt` inside generated/working dirs **or** ensure modules are formatted at source.

## Fixing TFLint findings

- Prefer **smallest change** that satisfies the rule (naming, types, deprecated attrs).
- If a rule is wrong for context, document **why** in the decision log and use a **narrow** `tflint-ignore` comment only on that line — not whole files.

## Scripts

Optional helper (run from repo root):

```bash
.cursor/skills/terraform-tflint-format/scripts/tf-quality.sh [terraform-root]
```

If the script is missing, run the commands above manually.
