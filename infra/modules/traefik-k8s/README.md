# Traefik K8s Gateway

This module installs and configures Traefik in k8s from the Helm chart. It requires:

- [metal-lb](https://metallb.universe.tf/installation/)
- [Authelia](https://www.authelia.com/)

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