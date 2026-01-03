include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/paperless-ngx"
}

locals {
  sensitive_vars = yamldecode(sops_decrypt_file("./paperless_vars.sops.yaml"))
}

inputs = {
  kubeconfig_paths = [
    "${get_terragrunt_dir()}/.kube/config",
    "${get_env("HOME")}/.kube/config",
  ]

  namespace = "paperless-ngx"
  ingress_namespaces = ["traefik"]

  # Database password - SECURITY: Set via environment variable or SOPS-encrypted .env file
  # The default "paperless" password is ONLY for initial testing - change immediately!
  postgres_password = local.sensitive_vars.postgres_password

  # Storage class names
  nfs_storage_class_name   = "nfs-retain"
  iscsi_storage_class_name = "iscsi-retain"
  paperless_env_vars = {
    PAPERLESS_URL = local.sensitive_vars.paperless_url
    PAPERLESS_CSRF_TRUSTED_ORIGINS = local.sensitive_vars.paperless_csrf_trusted_origins
    PAPERLESS_USE_X_FORWARD_HOST = "true"
    PAPERLESS_PROXY_SSL_HEADER = jsonencode(["HTTP_X_FORWARDED_PROTO", "https"])
    PAPERLESS_CONSUMER_POLLING = "30"
    PAPERLESS_OCR_LANGUAGES = "eng jpn"
    PAPERLESS_OCR_LANGUAGE = "eng+jpn"
  }

  # Storage sizes (inherited from original k8s manifests)
  # NOTE: These are minimal sizes suitable for testing. For production use, consider:
  # - db_storage_size: 10Gi or more
  # - webserver_media_storage_size: 50Gi or more
  # - webserver_data_storage_size: 10Gi or more
  db_storage_size                 = "100Mi"
  broker_storage_size             = "100Mi"
  webserver_data_storage_size     = "100Mi"
  webserver_media_storage_size    = "100Mi"
  webserver_export_storage_size   = "100Mi"
  webserver_consume_storage_size  = "100Mi"
}
