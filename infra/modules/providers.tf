terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc05"
    }
  }
}



# provider "proxmox" {
#   pm_api_url      = var.proxmox_api_url
#   pm_api_token_id = var.proxmox_api_token_id
#   pm_api_token_secret = var.proxmox_api_token_secret
#   pm_tls_insecure = true
# }

provider "proxmox" {
  pm_api_url      = "https://192.168.1.203:8006/api2/json"
  pm_api_token_id = "terraform-prov@pve!iac-token"
  pm_api_token_secret = "15327108-8272-43e3-a140-d9308851f3f1"
  pm_tls_insecure = true
}