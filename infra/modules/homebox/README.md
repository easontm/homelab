# HomeBox

This module provisions [HomeBox](https://homebox.software/) as a Proxmox LXC created directly from the upstream OCI image.

Unlike the Authelia module, the first pass here is Terraform-only. HomeBox configuration is supplied through `HBOX_*` environment variables using the `environment_variables` support built into `proxmox_virtual_environment_container`.

## Defaults

The module sets production-oriented defaults that align with the upstream container image:

- image: `ghcr.io/sysadminsmedia/homebox:latest`
- internal web port: `7745`
- SQLite database stored under `/data/homebox.db`
- analytics disabled
- self-registration enabled
- local username/password login enabled
- thumbnails enabled
- `trust_proxy` disabled unless you opt in

A dedicated volume mount is created at `/data` so the HomeBox database and uploads persist outside the container root filesystem.

## Configuration

Common HomeBox settings are exposed via the `homebox_config` object variable. Any advanced or newly added upstream settings can still be passed through `homebox_environment_overrides`.

Example:

```hcl
homebox_config = {
  options_trust_proxy  = true
  options_hostname     = "homebox.example.com"
  oidc_enabled         = true
  oidc_issuer_url      = "https://auth.example.com/application/o/homebox/"
  oidc_client_id       = "homebox"
  oidc_client_secret   = "super-secret"
}

homebox_environment_overrides = {
  HBOX_LABEL_MAKER_LABEL_SERVICE_URL = "https://labelmaker.example.com"
}
```

## Rootless image note

HomeBox publishes `-rootless` image variants, but this module defaults to the regular image tag. That keeps `/data` persistence straightforward inside an unprivileged LXC because the mounted data volume does not need extra ownership remapping for a non-root process. If you want the rootless image, set `container_tag = "latest-rootless"` (or another `*-rootless` tag) and ensure your mounted `/data` volume permissions are compatible.
