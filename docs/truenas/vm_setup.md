# Cloud-Init VM on TrueNAS

This is a re-writing of [this](https://blog.robertorosario.com/setting-up-a-vm-on-truenas-scale-using-cloud-init/)
post by Robert Rosario. Including it here for my own archive, as well as in
case the images embedded in the post go down. Also I have some of my own notes
to add.

1. Get the cloud-init image. [Releases](https://cloud-images.ubuntu.com/releases/24.04/)
   1. Should be `...cloudimg-amd64.img`
   2. `wget` on the TrueNAS terminal is probably the easiest way to do this
2. Create a zvol for the VM
   1. In the UI, or shell with `zfs create -V 20G vms/cloud-init-test`
3. Copy cloud image into zvol
   1. `qemu-img convert -O raw /downloads/ISOs/ubuntu-22.04-server-cloudimg-amd64.img /dev/zvol/vms/cloud-init-test`
4. Create the cloud-init seed image
   1. You need `cloud-utils` for this, and TrueNAS doesn't like you installing
   stuff. So I just spun up a Debian LXC in Proxmox to run these steps.
      1. Install `cloud-utils`
      2. Create the user-data.yaml file
        ```yaml
        #cloud-config
        chpasswd:
        list: |
            ubuntu:12345
        expire: False

        hostname: cloud-init-test

        ssh_authorized_keys:
        - ssh-rsa AAAAB3Nza...
        ```
      3. Create cloud-init seed image. Note I have modified this command from the blog.
        ```
        cloud-localds --verbose cloud-init-test-seed.qcow2 user-data.yaml
        ```
      4. I then extracted this from Proxmox by performing `pct mount <LXC ID>` 
        and using `scp` to copy it from Proxmox to my local machine.
      5. Copy the cloud-init seed image to TrueNAS
         1. `scp cloud-init-test-seed.qcow2 root@truenas:/mnt/vms/`
         2. Note: I had trouble with this with my setup, so I copied the file
            to my SMB share via my local machine and then moved it within
            TrueNAS using the terminal.
5. Create the VM
   1. System clock: local
   2. Boot method: Legacy BIOS
   3. Use existing disk image: VirtIO, select the zvol you made
   4. Installation media: do nothing
6. After the VM is made (but before you start it), add the cloud-init disk as 
   a device.
   1. VM -> Devices -> Add -> CD-ROM -> Select the qcow2 file.
   2. Make the boot order last (e.g. 1005)
7. Start!
