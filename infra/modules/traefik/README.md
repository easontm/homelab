# Traefik

This is currently implemented by using Proxmox's OCI -> LXC converter on the
image `traefik`.

## Setup

To set up, copy this folder (`traefik/`) to the Proxmox host where the container
will have access to storage. For example:

```
/mnt/pve/pve-shared/ct/traefik/
```

The folder structure here is designed to match what Traefik expects for ease of
use.

You will also need to provide the certificates as specified in
`traefik.yaml -> tls.certs`.

To perform mounting, edit `/etc/pve/lxc/<CONTAINER_ID>.conf` and add lines like
this:
```
mp0: /mnt/pve/pve-shared/ct/traefik/traefik,mp=/etc/traefik
```
