# ConfigMap for bootstrap user config JSON files
resource "kubernetes_config_map_v1" "bootstrap_users" {
  count = var.bootstrap_enabled ? 1 : 0

  metadata {
    name      = "lldap-bootstrap-users"
    namespace = kubernetes_namespace_v1.lldap.metadata[0].name
  }

  data = var.bootstrap_user_configs
}

# ConfigMap for bootstrap group config JSON files
resource "kubernetes_config_map_v1" "bootstrap_groups" {
  count = var.bootstrap_enabled ? 1 : 0

  metadata {
    name      = "lldap-bootstrap-groups"
    namespace = kubernetes_namespace_v1.lldap.metadata[0].name
  }

  data = var.bootstrap_group_configs
}

# One-shot Job that runs bootstrap.sh from within the LLDAP image to seed users and groups.
# The script is idempotent — it can be re-run safely when configs change.
resource "kubernetes_job_v1" "bootstrap" {
  count = var.bootstrap_enabled ? 1 : 0

  metadata {
    name      = "lldap-bootstrap"
    namespace = kubernetes_namespace_v1.lldap.metadata[0].name
  }

  spec {
    # Keep the job around after completion for log inspection
    ttl_seconds_after_finished = 3600

    template {
      metadata {}

      spec {
        restart_policy = "OnFailure"

        container {
          name    = "bootstrap"
          image   = "${var.lldap_image_repository}:${var.lldap_image_tag}"
          command = ["/app/bootstrap.sh"]
          env {
            name  = "LLDAP_URL"
            value = "http://lldap-web.${kubernetes_namespace_v1.lldap.metadata[0].name}.svc.cluster.local:17170"
          }
          env {
            name  = "LLDAP_ADMIN_USERNAME"
            value = "admin"
          }
          env {
            name = "LLDAP_ADMIN_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.lldap.metadata[0].name
                key  = "LLDAP_LDAP_USER_PASS"
              }
            }
          }
          env {
            name  = "USER_CONFIGS_DIR"
            value = "/bootstrap/user-configs"
          }
          env {
            name  = "GROUP_CONFIGS_DIR"
            value = "/bootstrap/group-configs"
          }

          volume_mount {
            name       = "user-configs"
            mount_path = "/bootstrap/user-configs"
            read_only  = true
          }
          volume_mount {
            name       = "group-configs"
            mount_path = "/bootstrap/group-configs"
            read_only  = true
          }
        }

        volume {
          name = "user-configs"
          config_map {
            name = kubernetes_config_map_v1.bootstrap_users[0].metadata[0].name
          }
        }
        volume {
          name = "group-configs"
          config_map {
            name = kubernetes_config_map_v1.bootstrap_groups[0].metadata[0].name
          }
        }
      }
    }
  }

  wait_for_completion = false
  depends_on          = [kubernetes_deployment_v1.lldap]
}
