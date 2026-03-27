#!/usr/bin/env bash
set -euo pipefail

# Run from repo root or pass a Terraform root directory.
ROOT="${1:-.}"

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform not found in PATH" >&2
  exit 1
fi
if ! command -v tflint >/dev/null 2>&1; then
  echo "tflint not found in PATH" >&2
  exit 1
fi

echo "==> terraform fmt (recursive)"
terraform -chdir="$ROOT" fmt -recursive

echo "==> terraform validate"
if ! terraform -chdir="$ROOT" init -backend=false >/dev/null 2>&1; then
  echo "terraform init -backend=false failed in $ROOT — fix providers/backend before validate" >&2
  exit 1
fi
terraform -chdir="$ROOT" validate

echo "==> tflint"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
TARGET="$(cd "$ROOT" && pwd)"
(
  cd "$REPO_ROOT"
  tflint --init
  tflint "$TARGET"
)

echo "OK: fmt, validate, tflint"
