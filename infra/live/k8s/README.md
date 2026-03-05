# k8s LIVE!

This folder contains my live Kubernetes configurations. Each folder in this
one represents a kubernetes namespace. Correspondingly, it has a `.kube/config`
file which gets loaded via the `.envrc` script. Generally, one namespace is
one installation, but the `kube-system` directory is a case where more than
one thing is installed in the same place, and it therefore has subdirectories.

The general order for installing k8s infra from nothing is:

1. Storage, if needed
   1. `nfs-csi`
   2. `democratic-csi`
2. `metrics-server`
3. `cert-manager`
4. `metal-lb`
5. `traefik`
6. Applications

> [!NOTE]
> My Traefik config uses an Authelia middleware managed as a Proxmox LXC.
> If using this, it should be installed before the applications.

## Networking

All internet-sourced traffic comes through a Cloudflare tunnel and is directed
at Traefik. Traefik is therefore the guard and the map.
- It directs unauthenticated users to Authelia
- Inbound traffic has no way to get to other resources without a defined
  Traefik route.
See the Traefik module's README for more.
