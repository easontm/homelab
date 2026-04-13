# HomeBox

This module provisions [HomeBox](https://homebox.software/) as a Proxmox LXC created directly from the upstream OCI image.

HomeBox configuration is supplied through `HBOX_*` environment variables using the `environment_variables` support built into `proxmox_virtual_environment_container`.

## Dealing with a bug

‼️ You need to apply this module twice ‼️

There's a bug in the Proxmox provider container resource for OCI containers 
[here](https://github.com/bpg/terraform-provider-proxmox/issues/2789). Envvars
won't get set on the first pass. Also due to this bug there are some extra
default settings specified that shouldn't be strictly necessary but it's good
for consistency.

## Rootless image note

HomeBox publishes `-rootless` image variants, but this module defaults to the regular image tag. That keeps `/data` persistence straightforward inside an unprivileged LXC because the mounted data volume does not need extra ownership remapping for a non-root process. If you want the rootless image, set `container_tag = "latest-rootless"` (or another `*-rootless` tag) and ensure your mounted `/data` volume permissions are compatible.
