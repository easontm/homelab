# PostgreSQL Secret
resource "kubernetes_secret_v1" "db_secret" {
  count = local.postgres_enabled ? 1 : 0

  metadata {
    name      = "db-secret"
    namespace = kubernetes_namespace_v1.authelia.metadata[0].name
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
    namespace = kubernetes_namespace_v1.authelia.metadata[0].name
  }

  spec {
    storage_class_name = var.db_storage_class
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
    namespace = kubernetes_namespace_v1.authelia.metadata[0].name
    labels = {
      app       = "authelia"
      component = "db"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app       = "authelia"
        component = "db"
      }
    }

    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app       = "authelia"
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
    namespace = kubernetes_namespace_v1.authelia.metadata[0].name
  }

  spec {
    selector = {
      app       = "authelia"
      component = "db"
    }

    port {
      port = 5432
    }
  }
}

# Backup PVC
resource "kubernetes_persistent_volume_claim_v1" "backup" {
  count = local.backup_active ? 1 : 0

  wait_until_bound = false

  metadata {
    name      = "pgdump-backup"
    namespace = kubernetes_namespace_v1.authelia.metadata[0].name
  }

  spec {
    storage_class_name = coalesce(var.backup_storage_class, var.db_storage_class)
    access_modes       = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.backup_storage_size
      }
    }
  }
}

# pg_dump backup CronJob
resource "kubernetes_cron_job_v1" "pgdump_backup" {
  count = local.backup_active ? 1 : 0

  metadata {
    name      = "pgdump-backup"
    namespace = kubernetes_namespace_v1.authelia.metadata[0].name
    labels = {
      app       = "authelia"
      component = "backup"
    }
  }

  spec {
    schedule                      = var.backup_schedule
    concurrency_policy            = "Forbid"
    successful_jobs_history_limit = var.backup_successful_jobs_history_limit
    failed_jobs_history_limit     = var.backup_failed_jobs_history_limit

    job_template {
      metadata {}

      spec {
        template {
          metadata {}

          spec {
            init_container {
              name    = "cleanup-old-dumps"
              image   = var.postgres_image
              command = ["find", "/backup", "-name", "authelia-*.pgdump", "-mtime", "+${var.backup_retention_days}", "-delete"]

              volume_mount {
                name       = "pgdump-backup"
                mount_path = "/backup"
              }
            }

            container {
              name    = "pgdump"
              image   = var.postgres_image
              command = ["/bin/sh", "-c"]
              args    = ["pg_dump -h db -U $PGUSER -d $PGDATABASE -F c -f /backup/authelia-$(date +%Y%m%d%H%M%S).pgdump"]

              env {
                name  = "PGUSER"
                value = var.postgres_user
              }

              env {
                name  = "PGDATABASE"
                value = var.postgres_database_name
              }

              env {
                name = "PGPASSWORD"
                value_from {
                  secret_key_ref {
                    name = kubernetes_secret_v1.db_secret[0].metadata[0].name
                    key  = "POSTGRES_PASSWORD"
                  }
                }
              }

              resources {
                limits = {
                  cpu    = "500m"
                  memory = "256Mi"
                }
                requests = {
                  cpu    = "50m"
                  memory = "64Mi"
                }
              }

              volume_mount {
                name       = "pgdump-backup"
                mount_path = "/backup"
              }
            }

            restart_policy = "OnFailure"

            volume {
              name = "pgdump-backup"
              persistent_volume_claim {
                claim_name = kubernetes_persistent_volume_claim_v1.backup[0].metadata[0].name
              }
            }
          }
        }
      }
    }
  }
}
