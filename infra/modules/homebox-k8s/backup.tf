# Backup PVC
resource "kubernetes_persistent_volume_claim_v1" "backup" {
  count = local.backup_active ? 1 : 0

  wait_until_bound = false

  metadata {
    name      = "pgdump-backup"
    namespace = kubernetes_namespace_v1.homebox.metadata[0].name
  }

  spec {
    storage_class_name = local.backup_storage_class_name
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
    namespace = kubernetes_namespace_v1.homebox.metadata[0].name
    labels = {
      app       = "homebox"
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
              command = ["find", "/backup", "-name", "homebox-*.pgdump", "-mtime", "+${var.backup_retention_days}", "-delete"]

              volume_mount {
                name       = "pgdump-backup"
                mount_path = "/backup"
              }
            }

            container {
              name    = "pgdump"
              image   = var.postgres_image
              command = ["/bin/sh", "-c"]
              args    = ["pg_dump -h db -U $PGUSER -d $PGDATABASE -F c -f /backup/homebox-$(date +%Y%m%d%H%M%S).pgdump"]

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
