locals {
  terraform_source_root = "${get_repo_root()}/infra/modules"
  proxmox_api_url = get_env("PROXMOX_API_URL")
  api_token       = "${get_env("PROXMOX_TF_USER_TOKEN_ID")}=${get_env("PROXMOX_TF_USER_TOKEN_VALUE")}"
}

generate "provider" {
  path      = "providers.tf"
  if_exists = "overwrite"
  contents  = file("${local.terraform_source_root}/providers.tf")
}

generate "variables" {
  path      = "pmx_variables.tf"
  if_exists = "overwrite"
  contents  = file("${local.terraform_source_root}/pmx_variables.tf")
}
