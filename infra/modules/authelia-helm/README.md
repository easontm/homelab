# authelia-helm

Deploys [Authelia](https://www.authelia.com/) via the official [Helm chart](https://charts.authelia.com).

## Design

Non-secret configuration is written as a real Helm values YAML file alongside the live stack (or
anywhere on disk). Secrets are passed as a YAML string generated at plan-time in `terragrunt.hcl`
from sops-decrypted variables.

## Usage

### 1. Copy the example values file to your live stack

```sh
cp ../../modules/authelia-helm/values.example.yaml infra/live/k8s/authelia/values.yaml
# edit values.yaml to match your environment
```

### 2. Create your live `terragrunt.hcl`

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/authelia-helm"
}

locals {
  secrets = yamldecode(sops_decrypt_file("./authelia_secrets.sops.yaml"))
}

inputs = {
  kubeconfig_paths = [
    "${get_terragrunt_dir()}/.kube/config",
    "${get_env("HOME")}/.kube/config",
  ]

  namespace          = "authelia"
  ingress_namespaces = ["traefik"]

  chart_version = "0.10.0"  # pin the chart version

  values_files = ["${get_terragrunt_dir()}/values.yaml"]

  # Secrets are generated from sops at plan-time as a YAML string.
  # Later values_files entries and this value override earlier ones.
  sensitive_values_yaml = yamlencode({
    configMap = {
      session = {
        encryption_key = { value = local.secrets.session_encryption_key }
      }
      storage = {
        encryption_key = { value = local.secrets.storage_encryption_key }
        postgres = {
          password = { value = local.secrets.postgres_password }
        }
      }
    }
  })
}
```

### 3. Structure your SOPS secrets file

```yaml
# authelia_secrets.sops.yaml (before encryption)
session_encryption_key: "<random 64-char string>"
storage_encryption_key: "<random 64-char string>"
postgres_password: "<strong password>"
```

## Auto-wired backends

The module can automatically configure Authelia backends when you set the corresponding variables.

### Session storage: Valkey

```hcl
valkey_enabled       = true
valkey_chart_version = "0.9.4"
valkey_storage_class = "iscsi-retain"
valkey_storage_size  = "256Mi"
# valkey_password = local.secrets.valkey_password  # optional
```

### Persistent storage: PostgreSQL

```hcl
db_type           = "postgres"
db_storage_class  = "iscsi-retain"
db_storage_size   = "2Gi"
postgres_password = local.secrets.postgres_password
```

### Authentication backend: LLDAP

When `lldap_enabled = true`, the module injects the Authelia LDAP configuration using the
built-in `lldap` implementation preset (sets correct LLDAP-specific attribute defaults) and
disables the file backend. You must already have LLDAP deployed (see `infra/modules/lldap-k8s`)
with a dedicated bind user for Authelia.

```hcl
lldap_enabled  = true
lldap_address  = "ldap://lldap-ldap.lldap.svc.cluster.local:3890"
lldap_base_dn  = local.secrets.lldap_base_dn
lldap_user     = local.secrets.lldap_user     # full bind DN, e.g. uid=authelia,ou=people,dc=example,dc=com
lldap_password = local.secrets.lldap_password
```

The `lldap_authelia_values` local is injected after Valkey and Postgres wiring but before
`sensitive_values_yaml`, so any field can still be overridden in `sensitive_values_yaml`.

The LLDAP `implementation` preset applies these defaults automatically:
- `username_attribute: uid`
- `additional_users_dn: ou=people`
- `additional_groups_dn: ou=groups`
- `group_search_mode: filter`
- `mail_attribute: mail`
- `display_name_attribute: displayName`

## Values file reference

See [`values.example.yaml`](./values.example.yaml) for a commented starting point.

The full chart values reference is at:
https://github.com/authelia/chartrepo/blob/master/charts/authelia/values.yaml

## Multiple values files

`values_files` is a list — you can split config across multiple files and they are merged in order
(last wins), exactly as Helm handles `--values` flags:

```hcl
values_files = [
  "${get_terragrunt_dir()}/values.yaml",
  "${get_terragrunt_dir()}/access-control.yaml",
]
```

`sensitive_values_yaml` is always appended last, so it always wins over file-based values.

## ReferenceGrant

A `ReferenceGrant` is created for each namespace listed in `ingress_namespaces`, allowing those
namespaces to route to the `authelia` Service via Gateway API HTTPRoutes (the same pattern used by
`homebox-k8s` and `traefik-k8s`).

## Notes

- Pin `chart_version` to avoid unexpected upgrades. Find available versions with:
  ```sh
  helm repo add authelia https://charts.authelia.com && helm search repo authelia/authelia --versions
  ```
- The chart creates and manages its own Kubernetes Secret for Authelia secrets when you pass
  `value:` fields. Use `secret.existingSecret` in your values YAML if you'd rather manage the
  secret yourself.
