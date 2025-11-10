# Infrastructure

## Installation

### 1. Ansible

`uv tool install ansible`
`uv tool install ansible-core`

### 2. Opentofu

`brew install opentofu`

## Initial Setup

To use the Proxmox provider, you need a user and token. Details [in the docs](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs).

```bash
pveum role add TerraformProv -privs "Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.PowerMgmt SDN.Use"
pveum user add terraform-prov@pve --password <password>
pveum aclmod / -user terraform-prov@pve -role TerraformProv
```

Then go to Datacenter -> Permissions -> API Tokens and uncheck `Privilege Separation`.