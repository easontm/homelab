include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/paperless-ngx"
}

locals {
  sensitive_vars = yamldecode(sops_decrypt_file("./paperless_vars.sops.yaml"))
  # This matches the mapall UID/GID in TrueNAS, k8s-nfs
  nfs_share_mapall_uid_gid = 3001
}

inputs = {
  kubeconfig_paths = [
    "${get_terragrunt_dir()}/.kube/config",
    "${get_env("HOME")}/.kube/config",
  ]

  paperless_ngx_image = "ghcr.io/paperless-ngx/paperless-ngx:2.20.11"
  namespace = "paperless-ngx"
  ingress_namespaces = ["traefik"]
  postgres_password = local.sensitive_vars.postgres_password

  nfs_storage_class_name   = "nfs-retain"
  consume_storage_class_name = "scan"
  iscsi_storage_class_name = "iscsi-retain"
  paperless_env_vars = {
    PAPERLESS_URL = local.sensitive_vars.paperless_url
    PAPERLESS_CSRF_TRUSTED_ORIGINS = local.sensitive_vars.paperless_csrf_trusted_origins
    PAPERLESS_USE_X_FORWARD_HOST = "true"
    PAPERLESS_PROXY_SSL_HEADER = jsonencode(["HTTP_X_FORWARDED_PROTO", "https"])
    PAPERLESS_CONSUMER_POLLING = "30"
    PAPERLESS_OCR_LANGUAGES = "eng jpn"
    PAPERLESS_OCR_LANGUAGE = "eng+jpn"
    PAPERLESS_DATE_PARSER_LANGUAGES = "en+ja"
    USERMAP_UID = local.nfs_share_mapall_uid_gid
    USERMAP_GID = local.nfs_share_mapall_uid_gid
  }

  # Backup
  backup_enabled      = true
  backup_schedule     = "0 2 * * *"
  backup_storage_size = "20Gi"

  # These should be roughly unchanging
  webserver_consume_storage_size  = "20Gi"
  broker_storage_size             = "512Mi"
  # Both storage types support resizing (I tested), so these can be increased as needed.
  db_storage_size                 = "10Gi"
  webserver_data_storage_size     = "15Gi"
  webserver_media_storage_size    = "200Gi"
  webserver_export_storage_size   = "10Gi"
  
}
