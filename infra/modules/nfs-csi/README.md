# NFS CSI Driver

This module installs the Helm chart for the [NFS CSI Driver](https://github.com/kubernetes-csi/csi-driver-nfs),
which enables Kubernetes to use NFS shares as resources for PVCs.

The Helm values can be found [here](https://github.com/kubernetes-csi/csi-driver-nfs/blob/master/charts/README.md).

## Setup

Installing this module requires a pre-existing NFS share on the network.
My lab uses TrueNAS, so that's where the setup is. There are some community
-driven TrueNAS Terraform providers, but they don't work past TrueNAS 25.

1. Create a user/group to own the dataset you'll share.
   1. User: uncheck all access boxes, leave passwordless
   2. Group: add no privileges, do not enable any sudo commands
2. Create a dataset (not zvol) on TrueNAS, set the owner/group to what you made
   in step 1.
3. Create an NFS share and point it at the dataset
   1. Set `Mapall User` and `Mapall Group` to the newly created user and group.
   2. Ensure the permissions on the dataset are `755`.
   3. User: all, group: read/execute, others: read/execute
4. Add your network CIDR or your K8s host IPs to the NFS share configuration.

## Testing

Here I also include a test PVC and pod to ensure it was set up correctly,
toggleable with the `test` variable. Note that `terragrunt destroy` doesn't seem to 
work properly here, so you may need to delete the pod/pvc yourself.

## Notes

This module currently only provisions one StorageClass, so its inputs are
pretty simple. It could easily be expanded to allow for more StorageClasses
and for specifying the various attributes of them, I just have no need now.
