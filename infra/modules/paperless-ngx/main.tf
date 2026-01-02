provider "kubernetes" {
  config_paths = var.kubeconfig_paths
}

# Namespace
resource "kubernetes_namespace" "paperless_ngx" {
  metadata {
    name = var.namespace
  }
}

# Secret for database password
resource "kubernetes_secret" "db_secret" {
  metadata {
    name      = "db-secret"
    namespace = kubernetes_namespace.paperless_ngx.metadata[0].name
  }

  data = {
    POSTGRES_PASSWORD = var.postgres_password
  }
}
