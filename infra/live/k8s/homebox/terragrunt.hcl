include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/homebox-k8s"
}

locals {
  sensitive_vars = yamldecode(sops_decrypt_file("./homebox_vars.sops.yaml"))
}

inputs = {
  kubeconfig_paths = [
    "${get_terragrunt_dir()}/.kube/config",
    "${get_env("HOME")}/.kube/config",
  ]
  namespace = "homebox"
  ingress_namespaces = ["traefik"]

  homebox_image_tag = "0.25.0"
  homebox_env_vars = {
    HBOX_OPTIONS_TRUST_PROXY = "true"
    HBOX_DATABASE_SSL_MODE  = "disable"
    # OIDC via Authelia — non-secret vars (client secret goes via oidc_client_secret below)
    HBOX_OPTIONS_OAUTH2_PROVIDER   = "generic-oidc"
    HBOX_OPTIONS_OAUTH2_CLIENT_ID  = "homebox"
    HBOX_OPTIONS_OAUTH2_ISSUER_URL = "https://auth.easontm.com"
  }

  # OIDC client secret — raw (unhashed) secret shared with Authelia.
  # Add 'oidc_client_secret: <raw_secret>' to homebox_vars.sops.yaml, then re-encrypt.
  # Generate with: openssl rand -base64 48
  # Hash for values.yaml: docker run --rm authelia/authelia:latest authelia crypto hash generate argon2 --password '<raw_secret>'
  oidc_client_secret = try(local.sensitive_vars.oidc_client_secret, null)
  data_storage_size = "5Gi"

  storage_class_name   = "nfs-retain"
  db_storage_class_name   = "iscsi-retain"
  db_type = "postgres"
  postgres_password = local.sensitive_vars.postgres_password
  db_storage_size = "2Gi"

  backup_enabled = true

  # Backup
  # backup_enabled      = true
  # backup_schedule     = "0 2 * * *"
  # backup_storage_size = "20Gi"

}
