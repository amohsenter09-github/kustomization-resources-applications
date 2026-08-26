# kustomization-resources-applications

Global Kubernetes manifests for the Weather, Air Quality, and Map microservices.

Application code and Dockerfiles live in the app repos. This repo owns Deployments, Services, HTTPRoutes, ConfigMaps, environment overlays, and the local Kind cluster topology.

All overlays currently deploy image tag **`01`**.

## Local Kind topology

Run three Kind clusters on Docker Desktop. Do not deploy apps until the clusters are up.

```
MacBook
   │
Docker Desktop
   │
   ├─ bootstrap      Kind   (platform, no app workloads)
   ├─ workload-dev   Kind   (cnpe-dev overlays)
   └─ workload-prod  Kind   (cnpe-prod overlays)
```

| Cluster | kubecontext | API | HTTP | HTTPS |
| --- | --- | --- | --- | --- |
| bootstrap | `kind-bootstrap` | `127.0.0.1:16443` | 8080 | 8443 |
| workload-dev | `kind-workload-dev` | `127.0.0.1:16444` | 8081 | 8444 |
| workload-prod | `kind-workload-prod` | `127.0.0.1:16445` | 8082 | 8445 |

```bash
bash scripts/kind-up.sh
bash scripts/kind-status.sh
bash scripts/kind-down.sh
```

`kind-up.sh` creates the clusters and installs ingress-nginx on **bootstrap** only (Argo CD). Workload clusters use Envoy Gateway.

When you are ready to deploy apps, use Argo CD from the sibling `bootstrap-control-plane` repo. Direct apply is only a fallback:

```bash
kubectl --context kind-workload-dev apply -k overlays/cnpe-dev
kubectl --context kind-workload-prod apply -k overlays/cnpe-prod
```

Leave `kind-bootstrap` for Argo CD. `overlays/local` is still available if you want a single-cluster apply.

## App mapping

| App repo | Kustomize path | Image | Service port | Container port | Deploy onto |
| --- | --- | --- | --- | --- | --- |
| [weather-api-fastapi](https://github.com/amohsenter09-github/weather-api-fastapi) | `apps/weather-api` | `weather-api:01` | 8000 | 8000 | workload-dev / workload-prod |
| [air-quality-api](https://github.com/amohsenter09-github/air-quality-api) | `apps/air-quality-api` | `air-quality-api:01` | 8001 | 8000 | workload-dev / workload-prod |
| [map-api](https://github.com/amohsenter09-github/map-api) | `apps/map-api` | `map-api:01` | 8002 | 8000 | workload-dev / workload-prod |

Each app has `base/` plus overlays for `local`, `cnpe-dev`, and `cnpe-prod`. Ingress `/` serves the GUI; `/docs` and the JSON APIs stay on the same Service.

## Cluster overlays

Apply all three apps at once (after Kind is up):

```bash
kubectl --context kind-workload-dev apply -k overlays/cnpe-dev
kubectl --context kind-workload-prod apply -k overlays/cnpe-prod
```

Apply one app:

```bash
kubectl --context kind-workload-dev apply -k apps/weather-api/overlays/cnpe-dev
```

Validate manifests:

```bash
bash scripts/kustomize-build.sh
```
