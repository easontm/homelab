# HomeBox

> [!WARNING]
> This module has some issues due to some funky OCI behavior on the part of Proxmox
> and the Terraform provider. See "Development Notes" down below. I am not currently
> deploying this module; I have reimplemented Homebox as a k8s module in homebox-k8s.

This module provisions [HomeBox](https://homebox.software/) as a Proxmox LXC created directly from the upstream OCI image.

HomeBox configuration is supplied through `HBOX_*` environment variables using the `environment_variables` support built into `proxmox_virtual_environment_container`.

## Database modes

The module supports two database modes via `db_type`:

- `sqlite` (default): keeps the existing single-container deployment and sets `HBOX_DATABASE_SQLITE_PATH` automatically.
- `postgres`: keeps the HomeBox container and provisions a second PostgreSQL container from the official OCI image.

When `db_type = "postgres"`, the module reuses HomeBox defaults for most PostgreSQL container settings and lets you override them with `postgres_*` inputs such as:

- `postgres_image`
- `postgres_operating_system_type`
- `postgres_vmid`
- `postgres_host_name`
- `postgres_ipv4_address`
- `postgres_gateway_ip`
- `postgres_database_host`
- `postgres_template_storage`
- `postgres_data_mount`
- `postgres_env_vars`

## Shared PostgreSQL settings

HomeBox and PostgreSQL share the same Terraform inputs for the values that must stay aligned:

- `postgres_user`
- `postgres_password`
- `postgres_database_name`

When `db_type = "postgres"`, the module derives these HomeBox envvars automatically:

- `HBOX_DATABASE_DRIVER=postgres`
- `HBOX_DATABASE_HOST`
- `HBOX_DATABASE_PORT=5432`
- `HBOX_DATABASE_USERNAME`
- `HBOX_DATABASE_PASSWORD`
- `HBOX_DATABASE_DATABASE`

It also derives these official PostgreSQL image envvars automatically:

- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `POSTGRES_DB`

That means you should not set `HBOX_DATABASE_USERNAME`, `HBOX_DATABASE_PASSWORD`, or `HBOX_DATABASE_DATABASE` inside `homebox_env_vars`. Any conflicting values in `homebox_env_vars` or `postgres_env_vars` are overridden by the shared typed inputs so the application and database remain in sync.

## PostgreSQL OCI image notes

The default PostgreSQL image is `docker.io/library/postgres:18`, which expects persistent storage at `/var/lib/postgresql`. This module therefore defaults `postgres_data_mount.path` to `/var/lib/postgresql`.

If you switch to another image family or tag that expects a different filesystem layout, override:

- `postgres_operating_system_type`
- `postgres_data_mount.path`
- `postgres_env_vars` (for extras such as `PGDATA`, `POSTGRES_INITDB_ARGS`, or `POSTGRES_HOST_AUTH_METHOD`)

If you use DHCP for the PostgreSQL container or need HomeBox to connect through a different DNS name or IP, set `postgres_database_host`.

## Example live-stack values

Typical `infra/live/proxmox/homebox/homebox_vars.sops.yaml` values for PostgreSQL look like this:

```yaml
db_type: "postgres"

postgres_user: "homebox"
postgres_password: "replace-me"
postgres_database_name: "homebox"

postgres_vmid: 601
postgres_host_name: "homebox-postgres"
postgres_ipv4_address: "10.10.30.4/24"
postgres_gateway_ip: "10.10.30.1"

# Optional official image extras.
# postgres_env_vars:
#   POSTGRES_HOST_AUTH_METHOD: "scram-sha-256"

homebox_env_vars:
  HBOX_DATABASE_SSL_MODE: "disable"
```

## Development Notes

Developing this module has been a huge back and forth of tradeoffs.

First, there is Proxmox LXC vs Kubernetes hosting:

1. Homebox is just an OCI image and can be self-sufficient. Max, you can add
   a separate Postgres container. So there shouldn't be a big reason to do
   this in K8s and deal with services, etc.
2. But the Proxmox terraform provider has some bugs which make applying
   annoying.
   1. You need to apply twice for envvars to work
   2. It seemingly overwrites the container's existing envvars and entrypoint
3. I was trying to have some stuff hosted outside of K8s for "practice"/
   diversity purposes. Plus, if Paperless makes a node shit the bed or 
   something it would be good to reduce the blast radius.
4. K8s lets me do cronjob backups easily (that is, trying to run the built-in
   export command).

Then there's sqlite vs Postgres:

1. SQLite strongly recommends against file-db-over-network. Which is what is
   happening if the data is hosted on NFS-based storage.
2. But SQLite means I only have to deal with one container and snapshotting is
   theoretically very easy.
3. Postgres is more work but comes with more reliable backup tooling.
4. Postgres also has better non-romaji index support for searching for things
   labeled in Japanese.

Then for Postgres there's OCI vs TurnkeyLinux vs PostgresOperator:

1. OCI is treating the DB more like cattle, and the TKL one is more like a pet.
   1. Booting the TKL one has like, a wizard to deal with. Not great.
2. But the TKL one doesn't have the OCI envvars issues described above.
3. The PostgresOperator creates a custom K8s resource, so it only works in k8s
   but it includes better features (such as backups).

### Dealing with a bug

‼️ You need to apply this module twice ‼️

There's a bug in the Proxmox provider container resource for OCI containers
[here](https://github.com/bpg/terraform-provider-proxmox/issues/2789). Envvars
won't get set on the first pass. Also due to this bug there are some extra
default settings specified that shouldn't be strictly necessary but it's good
for consistency.

### Rootless image note

HomeBox publishes `-rootless` image variants, but this module defaults to the regular image tag. That keeps `/data` persistence straightforward inside an unprivileged container because the mounted data volume does not need extra ownership remapping for a non-root process. If you want the rootless image, set `container_tag = "latest-rootless"` (or another `*-rootless` tag) and ensure your mounted `/data` volume permissions are compatible.
