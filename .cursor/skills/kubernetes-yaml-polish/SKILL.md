---
name: kubernetes-yaml-polish
description: Formats and normalises Kubernetes, Helm, and Argo CD YAML for consistent indentation, ordering, and readability. Use when editing manifests under charts/, argo/, k8s/, or *.yaml/*.yml, or when the user mentions yaml format, helm values polish, or GitOps manifests.
---

# Kubernetes / Helm / Argo YAML polish

## Goals

- **Diff-friendly** YAML: stable indentation, no gratuitous reordering of meaningful lists.
- **Consistent style** across `Application`, `ApplicationSet`, Helm `values.yaml`, and raw manifests.

## Formatting

Prefer **one** project-wide approach and stick to it:

1. **Prettier** (if `prettier` + YAML plugin present in repo):  
   `npx prettier --write "**/*.{yml,yaml}"`  
   Honour `.prettierignore` (exclude CRDs/vendor bundles if needed).

2. **yq** (when Prettier is not configured):  
   `yq -i -P '.' file.yaml` pretty-prints; use for single files or small batches.

3. **yamllint** (optional CI gate): if `.yamllint` exists, run `yamllint .` and fix **errors**; tune **warnings** only if noisy.

Do **not** change semantic content while “polishing” (no key renames, no value changes) unless the user asked for a functional fix.

## Structure conventions

- **Kubernetes**: `apiVersion`, `kind`, `metadata`, `spec` order is conventional; labels/annotations alphabetised **only** if the repo already does that elsewhere.
- **Helm values**: group by component; comment only non-obvious security or ops knobs.
- **Argo CD `Application`**: keep `source`, `destination`, `syncPolicy` in a predictable order matching existing apps in the repo.

## Before marking work done

- Grep for **trailing whitespace** in edited YAML.
- Ensure **no tab characters** in YAML files (spaces only).
