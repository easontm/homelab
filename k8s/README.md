## Kubernetes

This file is just for documenting my K8s setup in general, it is not associated
any individual module.

## Nodes

Most of my nodes are VMs hosted on Proxmox. However, I also have one VM hosted
on TrueNAS as well, because I have some cores and RAM to spare over there.

### Setting up a new node

See [here](./node_setup.md).

## Networking

All inbound domain-routed traffic to my cluster comes through Traefik. Even
non-k8s hosted services like Authelia are routed in this fashion. Inbound
traffic follows this path:

```
Cloudflare -> Tunnel -> Traefik -> Authelia middleware -> Traefik -> Resource
```

Other than the Traefik dashboard itself, I am using the Traefik implementation
of the Kubernetes Gateway API to manage my routes. Traefik is the only thing
that actually exposed on the cluster, and it does this by receiving a cluster-
external IP from a Metal-LB LoadBalancer service.

## Storage

I have three kinds of storage available:

- NFS - filesystem storage backed by TrueNAS, installed via `csi-driver-nfs`
- iSCSI - block storage backed by TrueNAS, installed via `democratic-csi`
- local - storage from the K8s host itself, installed via [local path provisioner](https://github.com/rancher/local-path-provisioner?tab=readme-ov-file) from Rancher.
  - This was my basic storage before I had a NAS, and currently only exists as a backup.
```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.32/deploy/local-path-storage.yaml
```
