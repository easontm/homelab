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
