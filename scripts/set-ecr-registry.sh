#!/usr/bin/env bash
# Set the AWS account ID prefix on every overlay image (Argo CD clones GitHub,
# so commit the result after the first terraform apply).
#
# Usage:
#   bash scripts/set-ecr-registry.sh                  # aws sts get-caller-identity
#   bash scripts/set-ecr-registry.sh 123456789012
#   ECR_REGISTRY=123456789012.dkr.ecr.eu-west-1.amazonaws.com bash scripts/set-ecr-registry.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLACEHOLDER="000000000000.dkr.ecr.eu-west-1.amazonaws.com"

if [[ -n "${ECR_REGISTRY:-}" ]]; then
  REGISTRY="$ECR_REGISTRY"
elif [[ -n "${1:-}" ]]; then
  if [[ "${1}" == *".dkr.ecr."* ]]; then
    REGISTRY="$1"
  else
    REGISTRY="${1}.dkr.ecr.eu-west-1.amazonaws.com"
  fi
else
  ACCOUNT="$(aws sts get-caller-identity --query Account --output text)"
  REGISTRY="${ACCOUNT}.dkr.ecr.eu-west-1.amazonaws.com"
fi

echo "Setting overlay images to ${REGISTRY}/cnpe/<app>"

python3 - "$ROOT" "$PLACEHOLDER" "$REGISTRY" <<'PY'
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
old, new = sys.argv[2], sys.argv[3]
changed = 0
for path in root.glob("apps/*/overlays/*/kustomization.yaml"):
    text = path.read_text(encoding="utf-8")
    updated = text.replace(old, new)
    # Also replace a previously written real registry so re-runs work.
    if old not in text:
        import re
        updated = re.sub(
            r"\d{12}\.dkr\.ecr\.eu-west-1\.amazonaws\.com",
            new,
            text,
        )
    if updated != text:
        path.write_text(updated, encoding="utf-8")
        changed += 1
        print(f"  {path.relative_to(root)}")
print(f"Updated {changed} overlay(s). Commit this repo so Argo CD can pull.")
PY
