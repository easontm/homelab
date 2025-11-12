# Completely untested
resource "proxmox_vm_qemu" "web" {
  name        = "web01"
  target_node = "pve1"
  clone       = "k8s-node"
  memory      = 2048
  cpu {
    cores = 1
  }
  # disk {
  #   size = "5G"
  #   slot = "ide0"
  # }
  network {
    id     = 0
    bridge = "vmbr0"
    model  = "virtio"
  }

  # Cloud-init options
  ssh_user        = "ubuntu"
  ssh_private_key = file("~/.ssh/proxmox")
  sshkeys         = file("~/.ssh/proxmox.pub")
  ciuser          = "ubuntu"
  cipassword      = "changeme"
  ipconfig0       = "ip=dhcp"

  # Optional: preseed cloud-init customization
  # cicustom = "user=local:snippets/web-init.yml"
}
