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

  # Database password - should be managed via SOPS or environment variable
  postgres_password = get_env("POSTGRES_PASSWORD", "paperless")

  storage_class_name = "local-path"

  # Container images
  postgres_image      = "docker.io/library/postgres:18"
  redis_image         = "docker.io/library/redis:8"
  paperless_ngx_image = "ghcr.io/paperless-ngx/paperless-ngx:latest"
  tika_image          = "docker.io/apache/tika:latest"
  gotenberg_image     = "docker.io/gotenberg/gotenberg:8.24"

  # Storage sizes
  db_storage_size                 = "100Mi"
  broker_storage_size             = "100Mi"
  webserver_data_storage_size     = "100Mi"
  webserver_media_storage_size    = "100Mi"
  webserver_export_storage_size   = "100Mi"
  webserver_consume_storage_size  = "100Mi"
}
