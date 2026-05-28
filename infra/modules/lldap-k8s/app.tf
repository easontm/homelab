# Secret for LLDAP credentials and signing keys
resource "kubernetes_secret_v1" "lldap" {
  metadata {
    name      = "lldap-secrets"
    namespace = kubernetes_namespace_v1.lldap.metadata[0].name
  }

  data = {
    LLDAP_JWT_SECRET     = var.jwt_secret
    LLDAP_KEY_SEED       = var.key_seed
    LLDAP_LDAP_USER_PASS = var.admin_password
  }
}

# ConfigMap for non-sensitive environment variables
resource "kubernetes_config_map_v1" "lldap_env" {
  metadata {
    name      = "lldap-env"
    namespace = kubernetes_namespace_v1.lldap.metadata[0].name
  }

  data = merge(
    var.lldap_env_vars,
    {
      LLDAP_LDAP_BASE_DN = var.ldap_base_dn
    }
  )
}

# PVC for SQLite database and LLDAP config under /data
resource "kubernetes_persistent_volume_claim_v1" "data" {
  wait_until_bound = false

  metadata {
    name      = "lldap-data"
    namespace = kubernetes_namespace_v1.lldap.metadata[0].name
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

# LLDAP Deployment
resource "kubernetes_deployment_v1" "lldap" {
  metadata {
    name      = "lldap"
    namespace = kubernetes_namespace_v1.lldap.metadata[0].name
    labels = {
      app = "lldap"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "lldap"
      }
    }

    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app = "lldap"
        }
      }

      spec {
        security_context {
          run_as_user  = var.uid
          run_as_group = var.gid
          fs_group     = var.gid
        }

        container {
          name  = "lldap"
          image = "${var.lldap_image_repository}:${var.lldap_image_tag}"

          security_context {
            run_as_non_root            = true
            allow_privilege_escalation = false
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.lldap_env.metadata[0].name
            }
          }

          env {
            name = "LLDAP_JWT_SECRET"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.lldap.metadata[0].name
                key  = "LLDAP_JWT_SECRET"
              }
            }
          }

          env {
            name = "LLDAP_KEY_SEED"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.lldap.metadata[0].name
                key  = "LLDAP_KEY_SEED"
              }
            }
          }

          env {
            name = "LLDAP_LDAP_USER_PASS"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.lldap.metadata[0].name
                key  = "LLDAP_LDAP_USER_PASS"
              }
            }
          }

          port {
            name           = "web"
            container_port = 17170
            protocol       = "TCP"
          }

          port {
            name           = "ldap"
            container_port = 3890
            protocol       = "TCP"
          }

          resources {
            limits = {
              cpu    = var.lldap_resources.limits.cpu
              memory = var.lldap_resources.limits.memory
            }
            requests = {
              cpu    = var.lldap_resources.requests.cpu
              memory = var.lldap_resources.requests.memory
            }
          }

          volume_mount {
            name       = "data"
            mount_path = "/data"
          }
        }

        restart_policy = "Always"

        # Prevent Kubernetes from injecting <SERVICE_NAME>_PORT env vars, which collide
        # with LLDAP's own LLDAP_LDAP_PORT config variable.
        enable_service_links = false

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.data.metadata[0].name
          }
        }
      }
    }
  }
}

# Service for the LLDAP web UI (port 17170)
resource "kubernetes_service_v1" "lldap_web" {
  metadata {
    name      = "lldap-web"
    namespace = kubernetes_namespace_v1.lldap.metadata[0].name
    labels = {
      app       = "lldap"
      component = "web"
    }
  }

  spec {
    selector = {
      app = "lldap"
    }

    port {
      name        = "web"
      port        = 17170
      target_port = 17170
    }
  }
}

# Service for the LLDAP LDAP port (3890) — accessible by in-cluster consumers such as Authelia
resource "kubernetes_service_v1" "lldap_ldap" {
  metadata {
    name      = "lldap-ldap"
    namespace = kubernetes_namespace_v1.lldap.metadata[0].name
    labels = {
      app       = "lldap"
      component = "ldap"
    }
  }

  spec {
    selector = {
      app = "lldap"
    }

    port {
      name        = "ldap"
      port        = 3890
      target_port = 3890
    }
  }
}
