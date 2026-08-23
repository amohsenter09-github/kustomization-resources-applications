# kustomization-resources-applications

Global Kubernetes manifests for the Weather, Air Quality, and Map microservices.

Application code and Dockerfiles live in the app repos. This repo owns Deployments, Services, Ingress, ConfigMaps, and environment overlays.

## Apps

- `apps/weather-api`
- `apps/air-quality-api`
- `apps/map-api`

Each app has `base/` plus overlays for `local` (kind), `cnpe-dev`, and `cnpe-prod`.

## Cluster overlays

Apply all three apps at once:

```bash
kubectl apply -k overlays/local
kubectl apply -k overlays/cnpe-dev
kubectl apply -k overlays/cnpe-prod
```

Apply one app:

```bash
kubectl apply -k apps/weather-api/overlays/cnpe-dev
```

Validate:

```bash
bash scripts/kustomize-build.sh
```

## Local kind

```bash
kind create cluster --name local-cluster --config kind-ingress-config.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl apply -k overlays/local
```

App images are built in the app repos:

- `weather-api:local`
- `air-quality-api:local`
- `map-api:local`
