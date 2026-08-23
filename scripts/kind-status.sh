#!/usr/bin/env bash
# Show Kind cluster and node status for the local topology.

set -euo pipefail

CLUSTERS=(bootstrap workload-dev workload-prod)

echo "Kind clusters:"
kind get clusters || true
echo ""

for name in "${CLUSTERS[@]}"; do
  context="kind-${name}"
  echo "===== ${name} (${context}) ====="
  if ! kubectl --context "$context" get nodes -o wide 2>/dev/null; then
    echo "  not reachable"
  fi
  echo ""
done
