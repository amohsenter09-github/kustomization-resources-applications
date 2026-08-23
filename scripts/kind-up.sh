#!/usr/bin/env bash
# Create the local Kind topology on Docker Desktop:
#   bootstrap, workload-dev, workload-prod
# Does not deploy application workloads.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

CLUSTERS=(bootstrap workload-dev workload-prod)
INGRESS_MANIFEST="https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.1/deploy/static/provider/kind/deploy.yaml"

if ! docker info >/dev/null 2>&1; then
  echo "Docker Desktop is not running. Start it, then re-run this script."
  exit 1
fi

for name in "${CLUSTERS[@]}"; do
  if kind get clusters 2>/dev/null | grep -qx "$name"; then
    echo "Cluster $name already exists."
    continue
  fi
  echo "Creating cluster $name ..."
  kind create cluster --name "$name" --config "$REPO_ROOT/clusters/${name}.yaml"
done

for name in "${CLUSTERS[@]}"; do
  context="kind-${name}"
  echo "Waiting for $context node to be Ready ..."
  kubectl --context "$context" wait --for=condition=Ready node --all --timeout=180s
  echo "Installing ingress-nginx on $name ..."
  kubectl --context "$context" apply -f "$INGRESS_MANIFEST"
done

for name in "${CLUSTERS[@]}"; do
  context="kind-${name}"
  echo "Waiting for ingress-nginx on $name ..."
  kubectl --context "$context" -n ingress-nginx wait --for=condition=available deploy/ingress-nginx-controller --timeout=300s
done

echo ""
echo "Kind topology is up."
echo "  kubectl --context kind-bootstrap get nodes"
echo "  kubectl --context kind-workload-dev get nodes"
echo "  kubectl --context kind-workload-prod get nodes"
echo ""
echo "Ingress (no apps deployed yet):"
echo "  bootstrap      http://127.0.0.1:8080"
echo "  workload-dev   http://127.0.0.1:8081"
echo "  workload-prod  http://127.0.0.1:8082"
