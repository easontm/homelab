# Homebox ConfigMap for environment variables
resource "kubernetes_config_map_v1" "homebox_env" {
  metadata {
    name      = "homebox-env"
    namespace = kubernetes_namespace_v1.homebox.metadata[0].name
  }

  data = merge(
    var.homebox_env_vars,
    local.homebox_database_env,
    {
      HBOX_MODE = "production"
    },
  )
}

# OIDC Secret — created only when oidc_client_secret is provided.
# Contains the raw client secret as HBOX_OPTIONS_OAUTH2_CLIENT_SECRET.
resource "kubernetes_secret_v1" "oidc" {
  count = var.oidc_client_secret != null ? 1 : 0

  metadata {
    name      = "homebox-oidc"
    namespace = kubernetes_namespace_v1.homebox.metadata[0].name
  }

  data = {
    HBOX_OPTIONS_OAUTH2_CLIENT_SECRET = var.oidc_client_secret
  }
}

# Homebox data PVC
resource "kubernetes_persistent_volume_claim_v1" "data" {
  wait_until_bound = false

  metadata {
    name      = "homebox-data"
    namespace = kubernetes_namespace_v1.homebox.metadata[0].name
  }

  spec {
    storage_class_name = var.storage_class_name
    access_modes       = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.data_storage_size
      }
    }
  }
}

# Homebox Deployment
resource "kubernetes_deployment_v1" "homebox" {
  metadata {
    name      = "homebox"
    namespace = kubernetes_namespace_v1.homebox.metadata[0].name
    labels = {
      app       = "homebox"
      component = "app"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app       = "homebox"
        component = "app"
      }
    }

    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app       = "homebox"
          component = "app"
        }
      }

      spec {
        container {
          name  = "homebox"
          image = "${var.homebox_image_repository}:${var.homebox_image_tag}"

          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.homebox_env.metadata[0].name
            }
          }

          dynamic "env" {
            for_each = local.postgres_enabled ? [1] : []
            content {
              name = "HBOX_DATABASE_PASSWORD"
              value_from {
                secret_key_ref {
                  name = kubernetes_secret_v1.db_secret[0].metadata[0].name
                  key  = "POSTGRES_PASSWORD"
                }
              }
            }
          }

          dynamic "env" {
            for_each = var.oidc_client_secret != null ? [1] : []
            content {
              name = "HBOX_OPTIONS_OAUTH2_CLIENT_SECRET"
              value_from {
                secret_key_ref {
                  name = kubernetes_secret_v1.oidc[0].metadata[0].name
                  key  = "HBOX_OPTIONS_OAUTH2_CLIENT_SECRET"
                }
              }
            }
          }

          port {
            container_port = 7745
            protocol       = "TCP"
          }

          resources {
            limits = {
              cpu    = var.homebox_resources.limits.cpu
              memory = var.homebox_resources.limits.memory
            }
            requests = {
              cpu    = var.homebox_resources.requests.cpu
              memory = var.homebox_resources.requests.memory
            }
          }

          volume_mount {
            name       = "data"
            mount_path = "/data"
          }
        }

        restart_policy = "Always"

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.data.metadata[0].name
          }
        }
      }
    }
  }

  depends_on = [kubernetes_deployment_v1.db]
}

# Homebox Service
resource "kubernetes_service_v1" "homebox" {
  metadata {
    name      = "homebox"
    namespace = kubernetes_namespace_v1.homebox.metadata[0].name
    labels = {
      app       = "homebox"
      component = "app"
    }
  }

  spec {
    selector = {
      app       = "homebox"
      component = "app"
    }

    port {
      name        = "7745"
      port        = 7745
      target_port = 7745
    }
  }
}
