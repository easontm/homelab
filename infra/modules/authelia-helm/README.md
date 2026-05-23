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
