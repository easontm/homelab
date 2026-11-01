# Traefik K8s Gateway

This module installs and configures Traefik in k8s from the Helm chart. It requires:

- [metal-lb](https://metallb.universe.tf/installation/)
- [Authelia](https://www.authelia.com/)
- [API Gateway CRDs](https://gateway-api.sigs.k8s.io/guides/getting-started/introduction/#installing-gateway-api)
- [Traefik CRDs](https://doc.traefik.io/traefik/reference/install-configuration/providers/kubernetes/kubernetes-crd/)

It assumes you are using Authelia as a middleware, but does not include any
management of Authelia itself.

## Adding services

This deployment is using the K8s Gateway API. To send traffic to a new service,
you should:

1. Create a `ReferenceGrant` in the target namespace which allows `HTTPRoute`
   objects in the Traefik namespace in the `from` block and whatever your target
   is in the `to` namespace, e.g. a `Service`.
2. Create an `HTTPRoute` in the Traefik namespace that indicates the hostname
   you want to use, any middlewares (auth), and the target service.
3. (If your target is outside k8s) Create a selector-less `Service` and 
   an `Endpoint` which points at your external IP.

## On Certificates

If you would like to use `no-tls-verify=false` on the Cloudflare tunnel
(to secure communication between the tunnel and Traefik), then you must
provide Traefik wth a Cloudflare Origin CA. If you don't, then this
module will require [cert-manager](https://cert-manager.io/docs/installation/helm/) to issue a self-signed cert.

## On CRDs

### Upgrading

```
# Update the chart repository
helm repo update
# Check current chart & Traefik version
helm search repo traefik/traefik
# Update Traefik CRDs
helm show crds traefik/traefik | kubectl apply --server-side --force-conflicts -f -
# Update Gateway API CRDs, if needed
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.1/standard-install.yaml
# Upgrade Traefik release
# helm upgrade traefik traefik/traefik
# We use IaC for this step.
```

### Why not manage them here?

There's no *official* Gateway API helm chart as of the time of writing. Previously,
this Helm chart included them but they were removed to make resource deployment
more controllable.
