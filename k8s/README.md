## Ingress

I am using the [Traefik implementation](https://doc.traefik.io/traefik/reference/install-configuration/providers/kubernetes/kubernetes-gateway/)
of the [Gateway API](https://gateway-api.sigs.k8s.io/).

## Storage

Without networked storage, I am using the [local path provisioner](https://github.com/rancher/local-path-provisioner?tab=readme-ov-file) from Rancher.

```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.32/deploy/local-path-storage.yaml
```