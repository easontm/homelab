include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/lldap-k8s"
}

locals {
  sensitive_vars = yamldecode(sops_decrypt_file("./lldap_vars.sops.yaml"))
}

inputs = {
  kubeconfig_paths = [
    "${get_terragrunt_dir()}/.kube/config",
    "${get_env("HOME")}/.kube/config",
  ]
  ingress_namespaces = ["traefik"]

  lldap_image_tag = "2026-05-26-debian-rootless"

  ldap_base_dn   = local.sensitive_vars.ldap_base_dn
  jwt_secret     = local.sensitive_vars.jwt_secret
  key_seed       = local.sensitive_vars.key_seed
  admin_password = local.sensitive_vars.admin_password

  # SQLite — prefer an iSCSI-backed storage class to avoid NFS+SQLite issues
  storage_class_name = "iscsi-retain"
  data_storage_size  = "1Gi"

  # Optional: uncomment and populate to seed initial users and groups on first apply
  bootstrap_enabled = true
  bootstrap_group_configs = {
    "lldap_admin.json"            = jsonencode({ name = "lldap_admin" })
    "lldap_password_manager.json" = jsonencode({ name = "lldap_password_manager" })
  }
  bootstrap_user_configs = {
    for user in local.sensitive_vars.users : "${user.username}.json" => jsonencode({
      id          = user.username
      email       = user.email
      displayName = user.username
      password    = user.password
      groups      = user.groups
    })
  }
}
