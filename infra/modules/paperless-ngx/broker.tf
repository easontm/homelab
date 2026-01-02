# Broker (Redis) PVC
resource "kubernetes_persistent_volume_claim" "redisdata" {
  metadata {
    name      = "redisdata"
    namespace = kubernetes_namespace.paperless_ngx.metadata[0].name
  }

  spec {
    storage_class_name = var.iscsi_storage_class_name
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
