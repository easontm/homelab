# Webserver PVCs
resource "kubernetes_persistent_volume_claim" "data" {
  metadata {
    name      = "data"
    namespace = kubernetes_namespace.paperless_ngx.metadata[0].name
  }

  spec {
    storage_class_name = var.nfs_storage_class_name
    access_modes       = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.webserver_data_storage_size
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "media" {
  metadata {
    name      = "media"
    namespace = kubernetes_namespace.paperless_ngx.metadata[0].name
  }

  spec {
    storage_class_name = var.nfs_storage_class_name
    access_modes       = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.webserver_media_storage_size
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "webserver_export" {
  metadata {
    name      = "webserver-export"
    namespace = kubernetes_namespace.paperless_ngx.metadata[0].name
  }

  spec {
    storage_class_name = var.nfs_storage_class_name
    access_modes       = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.webserver_export_storage_size
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "webserver_consume" {
  metadata {
    name      = "webserver-consume"
    namespace = kubernetes_namespace.paperless_ngx.metadata[0].name
  }

  spec {
    storage_class_name = var.nfs_storage_class_name
    access_modes       = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.webserver_consume_storage_size
      }
    }
  }
}

# Webserver ConfigMap for environment variables
resource "kubernetes_config_map" "webserver_env" {
  metadata {
    name      = "webserver-env"
    namespace = kubernetes_namespace.paperless_ngx.metadata[0].name
  }

  data = merge(
    {
      PAPERLESS_DBHOST                     = "db"
      PAPERLESS_REDIS                      = "redis://broker:6379"
      PAPERLESS_TIKA_ENABLED               = "1"
      PAPERLESS_TIKA_ENDPOINT              = "http://tika:9998"
      PAPERLESS_TIKA_GOTENBERG_ENDPOINT    = "http://gotenberg:3000"
    },
    var.paperless_env_vars
  )
}

# Webserver Deployment
resource "kubernetes_deployment" "webserver" {
  metadata {
    name      = "webserver"
    namespace = kubernetes_namespace.paperless_ngx.metadata[0].name
    labels = {
      app       = "paperless-ngx"
      component = "webserver"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app       = "paperless-ngx"
        component = "webserver"
      }
    }

    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app       = "paperless-ngx"
          component = "webserver"
        }
      }

      spec {
        container {
          name  = "webserver"
          image = var.paperless_ngx_image

          env_from {
            config_map_ref {
              name = kubernetes_config_map.webserver_env.metadata[0].name
            }
          }

          env {
            name = "PAPERLESS_DBPASS"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db_secret.metadata[0].name
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          port {
            container_port = 8000
            protocol       = "TCP"
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
            name       = "webserver-export"
            mount_path = "/usr/src/paperless/export"
          }

          volume_mount {
            name       = "webserver-consume"
            mount_path = "/usr/src/paperless/consume"
          }
        }

        restart_policy = "Always"

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.data.metadata[0].name
          }
        }

        volume {
          name = "media"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.media.metadata[0].name
          }
        }

        volume {
          name = "webserver-export"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.webserver_export.metadata[0].name
          }
        }

        volume {
          name = "webserver-consume"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.webserver_consume.metadata[0].name
          }
        }
      }
    }
  }
}

# Webserver Service
resource "kubernetes_service" "webserver" {
  metadata {
    name      = "webserver"
    namespace = kubernetes_namespace.paperless_ngx.metadata[0].name
    labels = {
      app       = "paperless-ngx"
      component = "webserver"
    }
  }

  spec {
    selector = {
      app       = "paperless-ngx"
      component = "webserver"
    }

    port {
      name        = "8000"
      port        = 8000
      target_port = 8000
    }
  }
}
