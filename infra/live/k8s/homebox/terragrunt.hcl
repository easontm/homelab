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

  homebox_image_tag = "0.26.2"
  homebox_env_vars = {
    HBOX_OPTIONS_TRUST_PROXY = "true"
    HBOX_DATABASE_SSL_MODE  = "disable"
    HBOX_AUTH_API_KEY_PEPPER = local.sensitive_vars.api_key_pepper
    # OIDC via Authelia — non-secret vars (client secret goes via oidc_client_secret below)
    HBOX_OIDC_ENABLED = true
    HBOX_OIDC_CLIENT_ID  = "homebox"
    HBOX_OPTIONS_ALLOW_LOCAL_LOGIN = false
    HBOX_OIDC_ISSUER_URL = "https://auth.${local.sensitive_vars.domain}"
    HBOX_OIDC_BUTTON_TEXT = "Log in with Authelia"
    HBOX_LOG_LEVEL = "info"
  }

  # OIDC client secret — raw (unhashed) secret shared with Authelia.
  # Add 'oidc_client_secret: <raw_secret>' to homebox_vars.sops.yaml, then re-encrypt.
  # Generate with: openssl rand -base64 48
  # Hash for values.yaml: docker run --rm authelia/authelia:latest authelia crypto hash generate argon2 --password '<raw_secret>'
  oidc_client_secret = local.sensitive_vars.oidc_client_secret
  data_storage_size = "5Gi"

  storage_class_name   = "nfs-retain"
  db_storage_class_name   = "iscsi-retain"
  db_type = "postgres"
  postgres_password = local.sensitive_vars.postgres_password
  db_storage_size = "2Gi"

  # Backup
  backup_enabled = true
  # backup_schedule     = "0 2 * * *"
  # backup_storage_size = "20Gi"

}
