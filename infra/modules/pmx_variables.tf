variable "proxmox_api_url" {
  description = "Proxmox API URL. Usually ends in :8006/api2/json"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API Token ID. Looks like root@pam!terraform"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API Token Secret"
  type        = string
}
