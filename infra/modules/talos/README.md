# Talos

This module creates Talos Linux VMs. It uses the `nocloud` images so that VMs
boot directly to Talos immediately. Because Proxmox can't natively download
and unpack `.xz` archives, this is done as a data source (I downloaded the
file myself and uploaded it to Proxmox).

Because my storage where I keep the image is shared, I can create VMs on any
PVE node with that attached storage. If you put the disk in a non-shared
datastore, you will be limited to creating VMs on that machine.

## Included features

The Talos image I'm using has NFS and iSCSI tools, so I also include a kernel
patch to enable iSCSI.

## Post-apply

Once the module is applied, you can get the kubeconfig either from the `output`
or by getting the the `talosctl` config first, then running

```shell
talosctl --nodes $CONTROL_PLANE_IP kubeconfig
```

If you want to use iSCSI, you'll need set up `talosctl` regardless because
that's how we get the initiator names:

```shell
talosctl read /etc/iscsi/initiatorname.iscsi -n $NODE_IP
```

## References:
- [Talos Terraform Provider](https://search.opentofu.org/provider/siderolabs/talos/latest)
