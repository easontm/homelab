locals {
  postgres_enabled = var.db_type == "postgres"

  db_storage_class_name     = coalesce(var.db_storage_class_name, var.storage_class_name)
  backup_storage_class_name = coalesce(var.backup_storage_class_name, var.storage_class_name)
  backup_active             = local.postgres_enabled && var.backup_enabled

  homebox_database_env = local.postgres_enabled ? {
    HBOX_DATABASE_DRIVER   = "postgres"
    HBOX_DATABASE_HOST     = "db"
    HBOX_DATABASE_PORT     = "5432"
    HBOX_DATABASE_USERNAME = var.postgres_user
    HBOX_DATABASE_DATABASE = var.postgres_database_name
    } : {
    HBOX_STORAGE_CONN_STRING  = "file:///?no_tmp_dir=true"
    HBOX_STORAGE_PREFIX_PATH  = "data"
    HBOX_DATABASE_SQLITE_PATH = "/data/homebox.db?_pragma=busy_timeout=2000&_pragma=journal_mode=WAL&_fk=1&_time_format=sqlite"
  }
}

# Secret for PostgreSQL password
resource "kubernetes_secret_v1" "db_secret" {
  count = local.postgres_enabled ? 1 : 0

  metadata {
    name      = "db-secret"
    namespace = kubernetes_namespace_v1.homebox.metadata[0].name
  }

  data = {
    POSTGRES_PASSWORD = var.postgres_password
  }
}

# PostgreSQL PVC
resource "kubernetes_persistent_volume_claim_v1" "pgdata" {
  count = local.postgres_enabled ? 1 : 0

  wait_until_bound = false

  metadata {
    name      = "pgdata"
    namespace = kubernetes_namespace_v1.homebox.metadata[0].name
  }

  spec {
    storage_class_name = local.db_storage_class_name
    access_modes       = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.db_storage_size
      }
    }
  }
}

# PostgreSQL Deployment
resource "kubernetes_deployment_v1" "db" {
  count = local.postgres_enabled ? 1 : 0

  metadata {
    name      = "db"
    namespace = kubernetes_namespace_v1.homebox.metadata[0].name
    labels = {
      app       = "homebox"
      component = "db"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app       = "homebox"
        component = "db"
      }
    }

    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app       = "homebox"
          component = "db"
        }
      }

      spec {
        container {
          name  = "db"
          image = var.postgres_image

          resources {
            limits = {
              cpu    = var.postgres_resources.limits.cpu
              memory = var.postgres_resources.limits.memory
            }
            requests = {
              cpu    = var.postgres_resources.requests.cpu
              memory = var.postgres_resources.requests.memory
            }
          }

          env {
            name  = "POSTGRES_DB"
            value = var.postgres_database_name
          }

          env {
            name  = "POSTGRES_USER"
            value = var.postgres_user
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.db_secret[0].metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
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
            claim_name = kubernetes_persistent_volume_claim_v1.pgdata[0].metadata[0].name
          }
        }
      }
    }
  }
}

# PostgreSQL Service
resource "kubernetes_service_v1" "db" {
  count = local.postgres_enabled ? 1 : 0

  metadata {
    name      = "db"
    namespace = kubernetes_namespace_v1.homebox.metadata[0].name
  }

  spec {
    selector = {
      app       = "homebox"
      component = "db"
    }

    port {
      port = 5432
    }
  }
}
