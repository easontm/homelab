# HomeBox

This module provisions [HomeBox](https://homebox.software/) as a Proxmox LXC created directly from the upstream OCI image.

HomeBox configuration is supplied through `HBOX_*` environment variables using the `environment_variables` support built into `proxmox_virtual_environment_container`.

## Database modes

The module now supports two database modes via `db_type`:

- `sqlite` (default): keeps the existing single-container deployment and sets `HBOX_DATABASE_SQLITE_PATH` automatically.
- `postgres`: keeps the HomeBox container, downloads the TurnKey PostgreSQL template `debian-12-turnkey-postgresql_18.1-1_amd64.tar.gz`, and provisions a second PostgreSQL LXC.

When `db_type = "postgres"`, the module derives sensible defaults for the PostgreSQL container from the HomeBox settings, but you can override them with `postgres_*` inputs such as:

- `postgres_vmid`
- `postgres_host_name`
- `postgres_ipv4_address`
- `postgres_gateway_ip`
- `postgres_database_host`
- `postgres_template_storage`
- `postgres_template_url`

The default template URL points at the TurnKey mirror network. If that mirror changes or a closer mirror works better in your environment, override `postgres_template_url`.

## Required HomeBox envvars for PostgreSQL

Upstream HomeBox expects these envvars when using PostgreSQL:

- `HBOX_DATABASE_DRIVER=postgres`
- `HBOX_DATABASE_HOST`
- `HBOX_DATABASE_PORT=5432`
- `HBOX_DATABASE_USERNAME`
- `HBOX_DATABASE_PASSWORD`
- `HBOX_DATABASE_DATABASE`

This module sets `HBOX_DATABASE_DRIVER` automatically when `db_type = "postgres"`, sets `HBOX_DATABASE_PORT` to `5432`, and derives `HBOX_DATABASE_HOST` from `postgres_database_host`, a static `postgres_ipv4_address`, or the PostgreSQL hostname.

You still need to provide the connection secrets in `homebox_env_vars`, typically through `infra/live/proxmox/homebox/homebox_vars.sops.yaml`:

```yaml
db_type: "postgres"
postgres_vmid: 601
postgres_host_name: "homebox-postgres"
postgres_ipv4_address: "10.10.30.4/24"
postgres_gateway_ip: "10.10.30.1"

homebox_env_vars:
  HBOX_DATABASE_USERNAME: "homebox"
  HBOX_DATABASE_PASSWORD: "replace-me"
  HBOX_DATABASE_DATABASE: "homebox"
```

The module validates those three `HBOX_DATABASE_*` values when `db_type = "postgres"` so the plan fails early if they are omitted.

The module provisions the TurnKey PostgreSQL appliance, but it does not create or manage the PostgreSQL user, password, or database inside that appliance for you. Make sure the credentials you configure in HomeBox match what you initialize in the TurnKey container.

If you use DHCP for the PostgreSQL LXC or need HomeBox to connect through a different DNS name or IP, also set `postgres_database_host` or override `HBOX_DATABASE_HOST` in `homebox_env_vars`.

## Dealing with a bug

‼️ You need to apply this module twice ‼️

There's a bug in the Proxmox provider container resource for OCI containers 
[here](https://github.com/bpg/terraform-provider-proxmox/issues/2789). Envvars
won't get set on the first pass. Also due to this bug there are some extra
default settings specified that shouldn't be strictly necessary but it's good
for consistency.

## Rootless image note

HomeBox publishes `-rootless` image variants, but this module defaults to the regular image tag. That keeps `/data` persistence straightforward inside an unprivileged LXC because the mounted data volume does not need extra ownership remapping for a non-root process. If you want the rootless image, set `container_tag = "latest-rootless"` (or another `*-rootless` tag) and ensure your mounted `/data` volume permissions are compatible.
