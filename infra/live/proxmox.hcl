locals {
  proxmox_api_url = get_env("PROXMOX_API_URL")
  proxmox_user    = get_env("PROXMOX_TF_USER_TOKEN_ID")
  proxmox_pass    = get_env("PROXMOX_TF_USER_TOKEN_VALUE")
}