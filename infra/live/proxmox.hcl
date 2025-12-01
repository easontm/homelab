locals {
  proxmox_api_url = get_env("PROXMOX_API_URL")
  api_token       = "${get_env("PROXMOX_TF_USER_TOKEN_ID")}=${get_env("PROXMOX_TF_USER_TOKEN_VALUE")}"
}
