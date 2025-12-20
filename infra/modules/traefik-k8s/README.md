# Traefik K8s Gateway

This requires
- the Gateway API [CRDs](# yoinked from https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/standard-install.yaml)
- the Traefik RBAC stuff is a Terraformed version of the manifests [here](https://raw.githubusercontent.com/traefik/traefik/v3.6/docs/content/reference/dynamic-configuration/kubernetes-gateway-rbac.yml).
- the Traefik [CRDs](https://raw.githubusercontent.com/traefik/traefik/v3.6/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml
))

- [cert-manager](https://cert-manager.io/docs/installation/helm/)