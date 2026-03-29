# Backup PVC (NFS)
resource "kubernetes_persistent_volume_claim_v1" "backup" {
  count = var.backup_enabled ? 1 : 0

  metadata {
    name      = "backup-export"
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

# Document exporter backup CronJob
resource "kubernetes_cron_job_v1" "document_export_backup" {
  count = var.backup_enabled ? 1 : 0

  metadata {
    name      = "document-export-backup"
    namespace = kubernetes_namespace_v1.paperless_ngx.metadata[0].name
    labels = {
      app       = "paperless-ngx"
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
              name    = "cleanup-old-exports"
              image   = var.paperless_ngx_image
              command = ["find", "/usr/src/paperless/export-backup", "-name", "export-*.zip", "-mtime", "+${var.backup_retention_days}", "-delete"]

              volume_mount {
                name       = "backup-export"
                mount_path = "/usr/src/paperless/export-backup"
              }
            }

            container {
              name  = "document-export-backup"
              image = var.paperless_ngx_image
              # command = ["document_exporter", "/usr/src/paperless/export-backup", "-d", "--no-progress-bar"]
              args = [
                "/usr/local/bin/document_exporter",
                "/usr/src/paperless/export-backup",
                "--zip",
                "--no-progress-bar"
              ]
              # I don't mount the whole configmap because then S6 tries to do a
              #bunch of stuff I don't care about.
              env {
                name  = "PAPERLESS_DBHOST"
                value = "db"
              }

              env {
                name = "PAPERLESS_DBPASS"
                value_from {
                  secret_key_ref {
                    name = kubernetes_secret_v1.db_secret.metadata[0].name
                    key  = "POSTGRES_PASSWORD"
                  }
                }
              }
              env {
                # https://github.com/paperless-ngx/paperless-ngx/issues/9631#issuecomment-2815816719
                name  = "S6_STAGE2_HOOK"
                value = "find /etc/s6-overlay/s6-rc.d/user/contents.d -type f -delete"
              }

              resources {
                limits = {
                  cpu    = "1"
                  memory = "2048Mi"
                }
                requests = {
                  cpu    = "100m"
                  memory = "256Mi"
                }
              }

              volume_mount {
                name       = "data"
                mount_path = "/usr/src/paperless/data"
              }

              volume_mount {
                name       = "media"
                mount_path = "/usr/src/paperless/media"
              }

              volume_mount {
                name       = "backup-export"
                mount_path = "/usr/src/paperless/export-backup"
              }
            }

            restart_policy = "OnFailure"

            volume {
              name = "data"
              persistent_volume_claim {
                claim_name = kubernetes_persistent_volume_claim_v1.data.metadata[0].name
              }
            }

            volume {
              name = "media"
              persistent_volume_claim {
                claim_name = kubernetes_persistent_volume_claim_v1.media.metadata[0].name
              }
            }

            volume {
              name = "backup-export"
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
