locals {
  cloudflare_account_id = get_env("CLOUDFLARE_ACCOUNT_ID")
}

remote_state {
  backend = "s3"

  config = {
    bucket  = "drinkteason-homelab-tfstate"
    key     = "${path_relative_to_include()}/terraform.tfstate"
    region  = "apac"
    endpoint = "https://${local.cloudflare_account_id}.r2.cloudflarestorage.com"

    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true

    use_lockfile = true
  }
}

# Generate backend.tf so I cannot accidentally reintroduce local
# state or override the backend per module.
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
terraform {
  backend "s3" {}
}
EOF
}
