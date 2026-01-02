# democratic-csi

[democratic-csi on GitHub](https://github.com/democratic-csi/democratic-csi)

## Setup

1. On TrueNAS, create the iSCSI datasets to store snapshots and volumes.
2. Create an API key for the CSI controller to use.
   1. To be honest I searched around for the privilege list but couldn't find it,
   and the list seems pretty long. So I'm using an admin token. Has some risk but
   I accept it.
3. On each of the k8s nodes, run the following:
    ```bash
    sudo apt install nfs-common open-iscsi multipath-tools scsitools lsscsi
    sudo cat <<EOF > /etc/multipath.conf
    defaults {
        user_friendly_names yes
        find_multipaths yes
    }
    EOF
    # Save the output of this step
    sudo cat /etc/iscsi/initiatorname.iscsi
    ```
4. On TrueNAS, add the saved Initiator Names from the k8s nodes to the 
   initiator list. (`Shares` -> `Block (iSCSI) Shares Targets` -> `Initiators`)
5. Apply the module
