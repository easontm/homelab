# Cluster API bundles

Manage pinned, vendored Kubernetes API definitions with the existing HashiCorp
Kubernetes provider. This module uses server-side apply, waits for CRDs to become
Established, and blocks resource destruction with `prevent_destroy`.

Gateway API recommends cluster admins or provisioning tools manage its CRDs;
they are shared cluster infrastructure. See the
[upstream management guide](https://gateway-api.sigs.k8s.io/guides/crd-management/).

## Why separate Terragrunt units?

`kubernetes_manifest` discovers schemas during **planning**, so `depends_on` inside
the Traefik module cannot make a missing HTTPRoute or Middleware schema available
for that same plan. Separate states let the CRDs be applied before consumers are
planned. This is also
[HashiCorp's recommended separation](https://developer.hashicorp.com/terraform/tutorials/kubernetes/kubernetes-provider#managing-custom-resources).

The live units are:

| Unit | Bundle | Purpose |
| --- | --- | --- |
| `infra/live/k8s/gateway-api-crds` | `gateway-api/1.6.3-standard` | Entire upstream Standard bundle, including its admission policy and binding |
| `infra/live/k8s/traefik-crds` | `traefik/42.1.3` | Proxy `traefik.io` definitions from chart 42.1.3; excludes Hub |

Traefik declares both as Terragrunt ordering dependencies and sets Helm
`skip_crds = true`. They are separate ownership/state boundaries; removing or
upgrading the controller does not implicitly remove or downgrade its APIs.
The controller version remains 38.0.0 until the upgrade runbook is executed.

Each unit reuses `../traefik/.kube/config`, then `$HOME/.kube/config`, in that
precedence order. It creates no namespace and needs cluster-wide permissions to
manage CRDs and, for Gateway, validating admission policies/bindings. The current
bundle is intended for the Kubernetes 1.35 cluster; check upstream prerequisites
before reusing it on older Kubernetes releases.

## Bootstrap a new cluster

After provisioning a reachable cluster and the usual storage, MetalLB and
cert-manager prerequisites, apply the API units first:

```bash
cd /Users/tylereason/projects/homelab/infra/live/k8s/gateway-api-crds
terragrunt apply
cd ../traefik-crds
terragrunt apply
cd ../traefik
terragrunt apply
```

Continue with applications after their prerequisites. On a cluster with existing
CRDs, do the adoption procedure below **before** applying the API units.

When running multiple units with `terragrunt run --all apply`, Terragrunt orders
the API units before Traefik. A plain `terragrunt apply` in Traefik does not apply
its dependencies automatically. A whole-stack **plan** on an empty cluster can
still fail because it does not actually install prerequisite schemas; use staged
applies for bootstrap. Other existing modules have their own prerequisites (for
example cert-manager must exist before planning a ClusterIssuer).

## Adopt CRDs already installed by Helm or kubectl

This is a one-time state migration, not a reinstall. Helm's native `crds/`
mechanism leaves existing CRDs in place; `skip_crds` stops future bundled
installation. If another Terraform state, templated Helm release or controller
actively manages these objects, stop and transfer that ownership first. Never
delete a CRD to make an import work.

1. Back up state, CRD definitions and the corresponding custom resources using
   the [upgrade runbook](../../../docs/runbooks/traefik-38-to-42-upgrade.md).
2. Inspect live bundle-version/channel annotations and `status.storedVersions`.
   Do not downgrade a newer installation, change experimental to Standard, or
   remove a still-stored API version. Resolve those cases before applying.
3. In each API unit, generate import commands for the matching existing objects,
   review them, then execute them. Missing objects will be created by the next
   apply; they should not be imported.

For the Gateway unit, run the following. For the Traefik unit, change `cd` to
`../traefik-crds` and set `BUNDLE=traefik/42.1.3`. Use a separate `IMPORT_DIR`
for each invocation. Python generates shell-quoted addresses with stable
`Kind/name` keys and the provider's cluster-scoped import ID format.

```bash
cd /Users/tylereason/projects/homelab/infra/live/k8s/gateway-api-crds
export KUBECONFIG="$PWD/../traefik/.kube/config:$HOME/.kube/config"
BUNDLE=gateway-api/1.6.3-standard
umask 077
IMPORT_DIR=$(mktemp -d /private/tmp/crd-adoption.XXXXXX)
kubectl get -f "../../../modules/kubernetes-crds/manifests/$BUNDLE" \
  --ignore-not-found -o json > "$IMPORT_DIR/existing.json"
python3 - "$IMPORT_DIR/existing.json" > "$IMPORT_DIR/import.sh" <<'PY'
import json
import shlex
import sys

with open(sys.argv[1]) as stream:
    result = json.load(stream)
items = result.get("items", []) if result.get("kind") == "List" else [result]
print("#!/bin/sh\nset -eu")
for item in items:
    kind = item["kind"]
    name = item["metadata"]["name"]
    key = f"{kind}/{name}"
    address = f"kubernetes_manifest.resource[{json.dumps(key)}]"
    resource_id = f"apiVersion={item['apiVersion']},kind={kind},name={name}"
    print(shlex.join(["terragrunt", "import", address, resource_id]))
PY
cat "$IMPORT_DIR/import.sh"
```

Review the commands while still in the matching unit, then run:

```bash
sh "$IMPORT_DIR/import.sh"
terragrunt plan
```

If retrying after a partial import, remove already-imported addresses from the
generated script (inspect `terragrunt state list`). Imports change Terraform
state, not Kubernetes objects. Review the subsequent plan: expect in-place
schema/annotation updates plus any missing definitions or admission resources.
Stop on destruction, unexpected changes or field-manager conflicts; identify and
reconcile the prior manager using the procedure below. The default does not force conflicts.
Import does not itself transfer server-side apply field ownership.

Apply Gateway and Traefik API units after importing each, then follow the
controller upgrade runbook. No live imports or applies were performed when
adding this module.

### Resolve a field-manager conflict during adoption

Terraform state ownership and Kubernetes field ownership are separate. Import
records the existing object in state. Kubernetes still remembers which manager
wrote its fields in `metadata.managedFields`. An update to a field owned by
`terraform-provider-helm` can therefore conflict with the new `homelab-crds`
manager, even after a successful import. See
[Kubernetes server-side apply](https://kubernetes.io/docs/reference/using-api/server-side-apply/#conflicts).

For example, conflicts on the HTTPRoute CRD's bundle-version annotation and
`spec.versions` mean the new bundle changes its recorded version and API schemas.
The `api-approved.kubernetes.io` annotation is an API-review reference, not an
RBAC grant. This is an actual CRD upgrade as well as an ownership handoff.

First check the live version/channel and stored API versions as above, and inspect
the previous manager if needed:

```bash
kubectl get crd httproutes.gateway.networking.k8s.io \
  -o yaml --show-managed-fields
```

If Helm was the previous installer and no tool is actively reconciling these
definitions, transfer the conflicting fields to the API unit. Keep the controller's
`skip_crds = true` configuration. If CRDs were installed through a templated Helm
chart, GitOps controller or another Terraform state, resolve that active owner's
configuration first. An old manager entry alone does not imply an active writer.

From `infra/live/k8s/gateway-api-crds`, use an explicit temporary allowlist:

```bash
terragrunt plan \
  -var='force_conflicts_for=["CustomResourceDefinition/httproutes.gateway.networking.k8s.io"]'
terragrunt apply \
  -var='force_conflicts_for=["CustomResourceDefinition/httproutes.gateway.networking.k8s.io"]'
```

Review the plan before applying. This permits takeover of conflicting fields
only on the listed object, not other bundle resources. It does not delete/recreate
the CRD or its HTTPRoute instances; schema/storage compatibility checks still apply.
If other objects report the same known prior installer, add their exact Kind/name
keys to the list after review. Re-run the plan after a partially failed apply;
some objects may already have updated successfully. Do not repeat completed imports.

Then run without the override:

```bash
terragrunt plan
terragrunt apply
terragrunt plan
```

The ordinary apply records `force_conflicts_for = []` again; inspect its plan
before accepting. The final plan should have no unexpected changes. Removing
the override does not give the old manager its fields back. Use the same process
in `traefik-crds` if its imported objects encounter an ownership conflict. Keep
the allowlist out of persistent live inputs so future conflicts remain visible.

## Bundle updates and lifecycle

There is no HTTP fetch, shell provisioner or hidden kubectl mutation during
Terraform apply. The reviewed source is local and versioned in Git. Source URLs,
artifact SHA-256 checksums and extraction scope are in
[`manifests/sources.json`](manifests/sources.json).

For an update, download a pinned official artifact, verify its source/checksum,
and add a new directory under `manifests/`. Gateway's multi-document release YAML
must be split into individual documents; include its non-CRD admission resources
too. Traefik's Proxy files are `traefik/crds/traefik.io_*.yaml` in the chart archive.
Keep upstream content intact, including license notices. Add the supported pin
to the `bundle` variable validation and change the matching live input. Stable
Kind/name keys keep existing objects at the same Terraform addresses.

Review removals and served/stored versions before applying; `prevent_destroy`
deliberately blocks removals/replacements. It does not prohibit an in-place
schema downgrade, so review the version pins and plan. It also cannot protect
objects if the resource block/configuration itself is removed. Intentional
decommissioning or ownership transfer requires a separate reviewed procedure;
do not use a routine stack destroy to remove shared CRDs.

Controller rollback normally retains the newer API bundles. Do not automatically
roll back their pins along with Traefik; CRD downgrades are a separate compatibility
and storage-version decision.
