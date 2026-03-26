# Backup PVC (NFS)
resource "kubernetes_persistent_volume_claim_v1" "backup" {
  count = var.backup_enabled ? 1 : 0

  metadata {
    name      = "backup-pgdata"
    namespace = kubernetes_namespace_v1.paperless_ngx.metadata[0].name
  }

  spec {
    storage_class_name = var.nfs_storage_class_name
    access_modes       = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.backup_storage_size
      }
    }
  }
}

# Database backup CronJob
resource "kubernetes_cron_job_v1" "db_backup" {
  count = var.backup_enabled ? 1 : 0

  metadata {
    name      = "db-backup"
    namespace = kubernetes_namespace_v1.paperless_ngx.metadata[0].name
    labels = {
      app       = "paperless-ngx"
      component = "db-backup"
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
            container {
              name    = "db-backup"
              image   = var.postgres_image
              command = ["/bin/bash", "-c"]
              args = [<<-EOT
                set -eo pipefail
                pg_dump -h db -U paperless paperless | gzip > /backup/paperless_$(date +%Y%m%d_%H%M%S).sql.gz
                find /backup -name '*.sql.gz' -mtime +${var.backup_retention_days} -delete
              EOT
              ]

              env {
                name = "PGPASSWORD"
                value_from {
                  secret_key_ref {
                    name = kubernetes_secret_v1.db_secret.metadata[0].name
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
                name       = "backup"
                mount_path = "/backup"
              }
            }

            restart_policy = "OnFailure"

            volume {
              name = "backup"
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
