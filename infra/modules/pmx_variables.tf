variable "proxmox_api_url" {
  description = "Proxmox API URL. Usually ends in :8006/api2/json"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API Token in the format id=secret"
  type        = string
}
