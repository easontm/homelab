# democratic-csi

## Setup

1. On TrueNAS, create the iSCSI volume and share.
   1. Set the portal to TrueNAS' IP address and the initiators to the k8s node IPs.
2. On each of the k8s nodes, run the following:
```bash
sudo apt install nfs-common open-iscsi multipath-tools scsitools lsscsi
sudo cat <<EOF > /etc/multipath.conf
defaults {
    user_friendly_names yes
    find_multipaths yes
}
EOF
```
