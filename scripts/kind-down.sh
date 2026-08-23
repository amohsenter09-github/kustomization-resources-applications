#!/usr/bin/env bash
# Delete the local Kind topology.

set -euo pipefail

CLUSTERS=(bootstrap workload-dev workload-prod)

for name in "${CLUSTERS[@]}"; do
  if kind get clusters 2>/dev/null | grep -qx "$name"; then
    echo "Deleting cluster $name ..."
    kind delete cluster --name "$name"
  else
    echo "Cluster $name does not exist."
  fi
done

echo "Kind topology is down."
