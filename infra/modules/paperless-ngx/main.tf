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

# Database (PostgreSQL) PVC
resource "kubernetes_persistent_volume_claim" "pgdata" {
  metadata {
    name      = "pgdata"
    namespace = kubernetes_namespace.paperless_ngx.metadata[0].name
    labels = {
      "io.kompose.service" = "pgdata"
    }
  }

  spec {
    storage_class_name = var.storage_class_name
    access_modes       = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.db_storage_size
      }
    }
  }
}

# Database Deployment
resource "kubernetes_deployment" "db" {
  metadata {
    name      = "db"
    namespace = kubernetes_namespace.paperless_ngx.metadata[0].name
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
        annotations = {
          "kompose.cmd"     = "kompose --file docker-compose.yaml convert"
          "kompose.version" = "1.37.0 (HEAD)"
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
                name = kubernetes_secret.db_secret.metadata[0].name
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
            claim_name = kubernetes_persistent_volume_claim.pgdata.metadata[0].name
          }
        }
      }
    }
  }
}

# Database Service
resource "kubernetes_service" "db" {
  metadata {
    name      = "db"
    namespace = kubernetes_namespace.paperless_ngx.metadata[0].name
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

# Broker (Redis) PVC
resource "kubernetes_persistent_volume_claim" "redisdata" {
  metadata {
    name      = "redisdata"
    namespace = kubernetes_namespace.paperless_ngx.metadata[0].name
    labels = {
      "io.kompose.service" = "redisdata"
    }
  }

  spec {
    storage_class_name = var.storage_class_name
    access_modes       = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.broker_storage_size
      }
    }
  }
}

# Broker Deployment
resource "kubernetes_deployment" "broker" {
  metadata {
    name      = "broker"
    namespace = kubernetes_namespace.paperless_ngx.metadata[0].name
    labels = {
      app       = "paperless-ngx"
      component = "broker"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app       = "paperless-ngx"
        component = "broker"
      }
    }

    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app       = "paperless-ngx"
          component = "broker"
        }
        annotations = {
          "kompose.cmd"     = "kompose --file docker-compose.yaml convert"
          "kompose.version" = "1.37.0 (HEAD)"
        }
      }

      spec {
        container {
          name  = "broker"
          image = var.redis_image

          volume_mount {
            name       = "redisdata"
            mount_path = "/data"
          }
        }

        restart_policy = "Always"

        volume {
          name = "redisdata"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.redisdata.metadata[0].name
          }
        }
      }
    }
  }
}

# Broker Service
resource "kubernetes_service" "broker" {
  metadata {
    name      = "broker"
    namespace = kubernetes_namespace.paperless_ngx.metadata[0].name
  }

  spec {
    selector = {
      app       = "paperless-ngx"
      component = "broker"
    }

    port {
      port = 6379
    }
  }
}

# Tika Deployment
resource "kubernetes_deployment" "tika" {
  metadata {
    name      = "tika"
    namespace = kubernetes_namespace.paperless_ngx.metadata[0].name
    labels = {
      app       = "paperless-ngx"
      component = "tika"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app       = "paperless-ngx"
        component = "tika"
      }
    }

    template {
      metadata {
        labels = {
          app       = "paperless-ngx"
          component = "tika"
        }
      }

      spec {
        container {
          name  = "tika"
          image = var.tika_image
        }

        restart_policy = "Always"
      }
    }
  }
}

# Tika Service
resource "kubernetes_service" "tika" {
  metadata {
    name      = "tika"
    namespace = kubernetes_namespace.paperless_ngx.metadata[0].name
  }

  spec {
    selector = {
      app       = "paperless-ngx"
      component = "tika"
    }

    port {
      port = 9998
    }
  }
}

# Gotenberg Deployment
resource "kubernetes_deployment" "gotenberg" {
  metadata {
    name      = "gotenberg"
    namespace = kubernetes_namespace.paperless_ngx.metadata[0].name
    labels = {
      app       = "paperless-ngx"
      component = "gotenberg"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app       = "paperless-ngx"
        component = "gotenberg"
      }
    }

    template {
      metadata {
        labels = {
          app       = "paperless-ngx"
          component = "gotenberg"
        }
      }

      spec {
        container {
          name  = "gotenberg"
          image = var.gotenberg_image

          args = [
            "gotenberg",
            "--chromium-disable-javascript=true",
            "--chromium-allow-list=file:///tmp/.*"
          ]
        }

        restart_policy = "Always"
      }
    }
  }
}

# Gotenberg Service
resource "kubernetes_service" "gotenberg" {
  metadata {
    name      = "gotenberg"
    namespace = kubernetes_namespace.paperless_ngx.metadata[0].name
  }

  spec {
    selector = {
      app       = "paperless-ngx"
      component = "gotenberg"
    }

    port {
      port = 3000
    }
  }
}

# Webserver PVCs
resource "kubernetes_persistent_volume_claim" "data" {
  metadata {
    name      = "data"
    namespace = kubernetes_namespace.paperless_ngx.metadata[0].name
    labels = {
      "io.kompose.service" = "data"
    }
  }

  spec {
    storage_class_name = var.storage_class_name
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
    labels = {
      "io.kompose.service" = "media"
    }
  }

  spec {
    storage_class_name = var.storage_class_name
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
    labels = {
      "io.kompose.service" = "webserver-export"
    }
  }

  spec {
    storage_class_name = var.storage_class_name
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
    labels = {
      "io.kompose.service" = "webserver-consume"
    }
  }

  spec {
    storage_class_name = var.storage_class_name
    access_modes       = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.webserver_consume_storage_size
      }
    }
  }
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

          env {
            name  = "PAPERLESS_DBHOST"
            value = "db"
          }

          env {
            name  = "PAPERLESS_REDIS"
            value = "redis://broker:6379"
          }

          env {
            name  = "PAPERLESS_TIKA_ENABLED"
            value = "1"
          }

          env {
            name  = "PAPERLESS_TIKA_ENDPOINT"
            value = "http://tika:9998"
          }

          env {
            name  = "PAPERLESS_TIKA_GOTENBERG_ENDPOINT"
            value = "http://gotenberg:3000"
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
