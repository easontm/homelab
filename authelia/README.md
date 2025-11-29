# Authelia

This is currently implemented by using Proxmox's OCI -> LXC converter on the
image `authelia/authelia`.

## Setup

To set it up, you should copy `configuration.yml` and `users_database.yml`  to
storage accessible to the container on the Proxmox host. For example:

```
/mnt/pve/pve-shared/ct/authelia/
```

Then these files need to be mounted to the container by editing
`/etc/pve/lxc/<CONTAINER_ID>.conf` with the line
```
mp0: /mnt/pve/pve-shared/ct/authelia,mp=/config
```
Replacing `mp0` with `mp#` if you need to use another mount point. This will put
the file in `/config/configuration.yml` as Authelia expects.

## Debugging

If the container doesn't start, try running the container locally and checking
your terminal logs:

```bash
docker run -v homelab/authelia:/config authelia/authelia:latest
```


## Notes

- Authelia expects a configuration file using the `yml` extension, not `yaml`