# Proxmox VLANs

> [!WARNING]
> This module modifies the network interfaces on your Proxmox host. You should probably ensure you have direct physical access to your machines just in case something goes wrong

This module sets up VLANs and Linux Bridges on your Proxmox hosts. If you
aren't using VLANs just skip this one.

This module assumes:
- you want every VLAN on every interface
- third octet is your VLAN ID.

Provide a list of hosts and a list of VLANs, and it will generate a matrix
of resources to apply.
