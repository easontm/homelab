generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
terraform {
  backend "local" {
    path = "./terraform.tfstate"
  }
}
EOF
}

# locals {
#   terraform_source_root = "${get_repo_root()}/infra/modules"
# }

# generate "provider" {
#   path      = "providers.tf"
#   if_exists = "overwrite"
#   contents  = file("${local.terraform_source_root}/providers.tf")
# }

# generate "variables" {
#   path      = "pmx_variables.tf"
#   if_exists = "overwrite"
#   contents  = file("${local.terraform_source_root}/pmx_variables.tf")
# }
