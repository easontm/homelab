# Database (PostgreSQL) PVC
resource "kubernetes_persistent_volume_claim_v1" "pgdata" {
  metadata {
    name      = "pgdata"
    namespace = kubernetes_namespace_v1.paperless_ngx.metadata[0].name
  }

  spec {
    storage_class_name = var.iscsi_storage_class_name
    access_modes       = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.db_storage_size
      }
    }
  }
}

# Database Deployment
resource "kubernetes_deployment_v1" "db" {
  metadata {
    name      = "db"
    namespace = kubernetes_namespace_v1.paperless_ngx.metadata[0].name
    labels = {
      app       = "paperless-ngx"
      component = "db"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app       = "paperless-ngx"
        component = "db"
      }
    }

    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app       = "paperless-ngx"
          component = "db"
        }
      }

      spec {
        container {
          name  = "db"
          image = var.postgres_image

          env {
            name  = "POSTGRES_DB"
            value = "paperless"
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.db_secret.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          env {
            name  = "POSTGRES_USER"
            value = "paperless"
          }

          volume_mount {
            name       = "pgdata"
            mount_path = "/var/lib/postgresql"
          }
        }

        restart_policy = "Always"

        volume {
          name = "pgdata"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.pgdata.metadata[0].name
          }
        }
      }
    }
  }
}

# Database Service
resource "kubernetes_service_v1" "db" {
  metadata {
    name      = "db"
    namespace = kubernetes_namespace_v1.paperless_ngx.metadata[0].name
  }

  spec {
    selector = {
      app       = "paperless-ngx"
      component = "db"
    }

    port {
      port = 5432
    }
  }
}
