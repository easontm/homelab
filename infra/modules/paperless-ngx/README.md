# paperless-ngx

This module installs [paperless-ngx](https://docs.paperless-ngx.com/). It was 
created by converting the official docker-compose file into individual
Kubernetes resources

## Pre-requisites

You must know your StorageClass name(s) for provisioning PVs. This module
supports specifying up to 3 separate StorageClasses.

1. General NFS storage
2. iSCSI block storage for the broker and DB (can use NFS but it's worse)
3. Storage for paperless' `consume` volume. This is separate in the case that
   you allow a scanner to upload to this storage over the network, and you
   dont want to grant the scanner generic access to your entire NFS storage.
   1. You can put in the same storage from #1 here if you don't care

## Setting up a scanner

I use a Brother MFC-L3780CDW and TrueNAS SCALE 25 as my storage provider,
and these steps reflect what I had to do.

1. Create a `scan` dataset in TrueNAS
2. Update the permissions so that the `k8s-nfs` group can also write to `scan`.
   1. Note: this group is my generic NFS dataset owner.
   2. Apply recursively so data created under `scan` get the same settings.
3. Create a `brother-printer` user and add it to the `k8s-nfs` group
4. Create an NFS share on my `scan` dataset.
   1. Authorized hosts: all my k8s nodes
   2. Mapall user/group: `k8s-nfs`
5. Apply the module
6. Create an SMB share for `<scans dataset>/<consume-pvc>`.
   1. You can find this by doing `kubectl get pv` and looking for the one
      bound to `paperless-ngx/webserver-consume`.
7. In the Brother UI, set
   1. "Network Folder Path" to `\\<TrueNAS IP>\<name of SMB share>`
   2. "Auth" to `Auto` and populate the credentials from the user you created.
8. Submit and then test connection
