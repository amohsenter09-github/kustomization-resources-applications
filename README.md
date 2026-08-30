# kustomization-resources-applications

Kustomize templates for the sample workloads. This repo does not contain app source or Helm operators.

Argo CD on the bootstrap cluster clones this repository and applies one overlay per app per environment. Operators (Envoy Gateway, Grafana, Prometheus, later Kyverno / Gatekeeper) live in [bootstrap-control-plane](https://github.com/amohsenter09-github/bootstrap-control-plane) as Helm charts.

## What this implements

```
apps/<service>/
  base/                 Deployment, Service, HTTPRoute, ConfigMap
  overlays/local        Kind single-cluster, image :01
  overlays/cnpe-dev     Scaleway workload-dev, registry :02
  overlays/cnpe-prod    Scaleway workload-prod, registry :02
```

Each `cnpe-*` overlay adds:

- Namespace
- In-cluster PostgreSQL (StatefulSet + ConfigMap)
- Image `rg.fr-par.scw.cloud/cnpe/<app>:02`
- HTTPRoute hostname (`*.cnpe-dev.cloud-master-ai.com` or `*-prod`)
- `imagePullPolicy` patch

`overlays/cnpe-dev` and `overlays/cnpe-prod` at the repo root apply all three apps at once. Prefer Argo CD Applications (`app-<service>-<env>`) over a direct `kubectl apply`.

## App mapping

| App | Path | Scaleway image | Kind image | Namespace (dev) |
| --- | --- | --- | --- | --- |
| [weather-api-fastapi](https://github.com/amohsenter09-github/weather-api-fastapi) | `apps/weather-api` | `rg.fr-par.scw.cloud/cnpe/weather-api:02` | `weather-api:01` | `weather-api-cnpe-dev` |
| [air-quality-api](https://github.com/amohsenter09-github/air-quality-api) | `apps/air-quality-api` | `rg.fr-par.scw.cloud/cnpe/air-quality-api:02` | `air-quality-api:01` | `air-quality-api-cnpe-dev` |
| [map-api](https://github.com/amohsenter09-github/map-api) | `apps/map-api` | `rg.fr-par.scw.cloud/cnpe/map-api:02` | `map-api:01` | `map-api-cnpe-dev` |

Service ports: weather **8000**, air-quality **8001**, map **8002**. Container port is **8000** for all three.

## Local Kind

Three clusters (`bootstrap`, `workload-dev`, `workload-prod`) match Scaleway names so Argo CD destinations do not change.

```bash
bash scripts/kind-up.sh
bash scripts/kind-status.sh
bash scripts/kind-down.sh
```

`kind-up.sh` installs ingress-nginx on **bootstrap** only. Workload clusters use Envoy Gateway from the control-plane repo.

Direct apply (fallback):

```bash
kubectl --context kind-workload-dev apply -k apps/weather-api/overlays/cnpe-dev
bash scripts/kustomize-build.sh
```

Leave `kind-bootstrap` for Argo CD.

## Related

- GitOps Applications: [bootstrap-control-plane](https://github.com/amohsenter09-github/bootstrap-control-plane)
- Clusters and registry: [scaleway-infrastructure](https://github.com/amohsenter09-github/scaleway-infrastructure)
