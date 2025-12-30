include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/paperless-ngx"
}

inputs = {
  kubeconfig_paths = [
    "${get_terragrunt_dir()}/.kube/config",
    "${get_env("HOME")}/.kube/config",
  ]

  namespace = "paperless-ngx"

  # Database password - SECURITY: Set via environment variable or SOPS-encrypted .env file
  # The default "paperless" password is ONLY for initial testing - change immediately!
  postgres_password = get_env("POSTGRES_PASSWORD", "paperless")

  storage_class_name = "local-path"

  # Container images
  postgres_image      = "docker.io/library/postgres:18"
  redis_image         = "docker.io/library/redis:8"
  paperless_ngx_image = "ghcr.io/paperless-ngx/paperless-ngx:latest"
  tika_image          = "docker.io/apache/tika:latest"
  gotenberg_image     = "docker.io/gotenberg/gotenberg:8.24"

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
