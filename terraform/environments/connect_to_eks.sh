#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: connect_to_eks.sh --env <name> [--alias <kube-context-name>]

  Reads Terraform state in terraform/environments/<name>/ and runs:
    aws eks update-kubeconfig --name <eks_cluster_name> --region <aws_region> [--profile ...]

  Region and optional AWS profile come from terraform.tfvars in that env (via terraform console).
  Override region: AWS_REGION or AWS_DEFAULT_REGION.

  Requires: terraform (initialized), aws CLI, credentials for the account.
USAGE
  exit "${1:-0}"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV=""
KUBE_ALIAS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env)
      ENV="${2:?}"
      shift 2
      ;;
    --alias)
      KUBE_ALIAS="${2:?}"
      shift 2
      ;;
    -h | --help)
      usage 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage 1
      ;;
  esac
done

[[ -n "$ENV" ]] || {
  echo "Missing --env" >&2
  usage 1
}

TF_DIR="${SCRIPT_DIR}/${ENV}"
[[ -d "$TF_DIR" ]] || {
  echo "No environment directory: ${TF_DIR}" >&2
  exit 1
}

tf_console() {
  terraform -chdir="$TF_DIR" console <<<"$1" | tr -d '\r\n'
}

strip_hcl_string() {
  local s="$1"
  case "$s" in
    null | tostring\(null\) | \"tostring\(null\)\" )
      echo ""
      return
      ;;
  esac
  s="${s#\"}"
  s="${s%\"}"
  printf '%s' "$s"
}

CLUSTER_NAME="$(terraform -chdir="$TF_DIR" output -raw eks_cluster_name)"

if [[ -n "${AWS_REGION:-}" ]]; then
  REGION="$AWS_REGION"
elif [[ -n "${AWS_DEFAULT_REGION:-}" ]]; then
  REGION="$AWS_DEFAULT_REGION"
else
  REGION="$(strip_hcl_string "$(tf_console 'var.aws_region')")"
fi
[[ -n "$REGION" ]] || {
  echo "Could not determine AWS region (set AWS_REGION or aws_region in terraform.tfvars)." >&2
  exit 1
}

PROFILE="$(strip_hcl_string "$(tf_console 'var.aws_profile == null ? "" : var.aws_profile')")"

AWS_CMD=(aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION")
if [[ -n "$PROFILE" ]]; then
  AWS_CMD+=(--profile "$PROFILE")
fi
if [[ -n "$KUBE_ALIAS" ]]; then
  AWS_CMD+=(--alias "$KUBE_ALIAS")
fi

echo "Cluster: ${CLUSTER_NAME}"
echo "Region:  ${REGION}"
if [[ -n "$PROFILE" ]]; then
  echo "Profile: ${PROFILE}"
fi
"${AWS_CMD[@]}"
