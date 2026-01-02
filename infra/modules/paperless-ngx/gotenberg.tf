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
