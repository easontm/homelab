terraform {
  required_version = ">= 1.10.6"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.87.0"
    }
    ansible = {
      source  = "ansible/ansible"
      version = "~> 1.3.0"
    }
  }
}



provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = var.proxmox_api_token
  insecure  = true
}
