# homebox-k8s

This module installs [Homebox](https://homebox.software/) on Kubernetes using native Terraform resources. It is the Kubernetes counterpart to the Proxmox-based `homebox` module and follows the resource conventions established by the `paperless-ngx` module.

## Pre-requisites

You must know your StorageClass name(s) for provisioning PersistentVolumes. One StorageClass is sufficient for both the app data and the database, but you can specify a separate class for each.

## Database modes

The module supports two database backends via `db_type`:

- `sqlite` (default): A single PVC is provisioned for `/data` and `HBOX_DATABASE_SQLITE_PATH` is set automatically. No additional pods are created.
- `postgres`: A PostgreSQL `Deployment` and `Service` are provisioned alongside Homebox. The DB credentials are stored in a Kubernetes `Secret` and injected into both pods automatically.

> **Note:** SQLite storage over NFS is discouraged by SQLite upstream. If your `storage_class_name` is NFS-backed, prefer `db_type = "postgres"` with an iSCSI/block-backed `db_storage_class_name`.

## Environment variables

Homebox is configured via `HBOX_*` environment variables. Use `homebox_env_vars` to pass additional variables:

```hcl
homebox_env_vars = {
  HBOX_WEB_MAX_UPLOAD_SIZE = "100"
}
```

The following variables are set automatically and **should not** be included in `homebox_env_vars`:

- `HBOX_MODE` — always set to `production`
- `HBOX_DATABASE_DRIVER`, `HBOX_DATABASE_HOST`, `HBOX_DATABASE_PORT`, `HBOX_DATABASE_USERNAME`, `HBOX_DATABASE_DATABASE`, `HBOX_DATABASE_PASSWORD` — set when `db_type = "postgres"`
- `HBOX_STORAGE_CONN_STRING`, `HBOX_STORAGE_PREFIX_PATH`, `HBOX_DATABASE_SQLITE_PATH` — set when `db_type = "sqlite"`

## Ingress

This module creates a `ReferenceGrant` for each namespace in `ingress_namespaces`, allowing those namespaces to route to the `homebox` Service (port 7745). This is the same pattern used by `paperless-ngx` for Traefik Gateway API integration.

```hcl
ingress_namespaces = ["traefik"]
```

You still need to create the `HTTPRoute` in your Traefik stack (outside this module).

## Example live-stack configuration

```hcl
# infra/live/k8s/homebox/terragrunt.hcl

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/homebox-k8s"
}

locals {
  sensitive_vars = yamldecode(sops_decrypt_file("./homebox_vars.sops.yaml"))
}

inputs = {
  kubeconfig_paths = [
    "${get_terragrunt_dir()}/.kube/config",
    "${get_env("HOME")}/.kube/config",
  ]

  namespace          = "homebox"
  ingress_namespaces = ["traefik"]

  db_type                = "postgres"
  postgres_password      = local.sensitive_vars.postgres_password
  db_storage_class_name  = "iscsi-retain"
  db_storage_size        = "5Gi"

  storage_class_name = "nfs-retain"
  data_storage_size  = "10Gi"

  homebox_env_vars = {
    HBOX_WEB_MAX_UPLOAD_SIZE = "100"
  }
}
```

Typical `homebox_vars.sops.yaml` structure:

```yaml
postgres_password: replace-me
```

## Backup (pg_dump)

When `db_type = "postgres"`, you can enable an automated pg_dump CronJob with `backup_enabled = true`. The job runs on the schedule defined by `backup_schedule` (default: daily at 2am), dumps the database in custom format (`.pgdump`) to a dedicated PVC, and an init container prunes files older than `backup_retention_days`.

```hcl
backup_enabled            = true
backup_schedule           = "0 2 * * *"
backup_storage_class_name = "nfs-retain"
backup_storage_size       = "10Gi"
backup_retention_days     = 7
```

To restore from a dump file:
```sh
kubectl exec -n homebox deploy/db -- pg_restore -h localhost -U homebox -d homebox -F c /backup/<file>.pgdump
```

`backup_enabled` has no effect when `db_type = "sqlite"`.



| Name | Description |
|------|-------------|
| `namespace` | Namespace where Homebox is deployed |
| `service_name` | Kubernetes Service name (`homebox`) |
| `cluster_ip` | ClusterIP assigned to the Homebox Service |
