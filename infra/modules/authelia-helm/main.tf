provider "helm" {
  kubernetes = {
    config_paths = var.kubeconfig_paths
  }
}

provider "kubernetes" {
  config_paths = var.kubeconfig_paths
}

resource "kubernetes_namespace_v1" "authelia" {
  metadata {
    name = var.namespace
  }
}

locals {
  postgres_enabled = var.db_type == "postgres"
  backup_active    = local.postgres_enabled && var.backup_enabled

  # When Valkey is enabled, auto-wire Authelia's session redis config.
  # Injected after values_files so it overrides any redis.enabled: false in the user's YAML,
  # but before sensitive_values_yaml so the user can still override individual fields.
  valkey_service_host = "valkey.${kubernetes_namespace_v1.authelia.metadata[0].name}.svc.cluster.local"

  valkey_authelia_values = var.valkey_enabled ? yamlencode({
    configMap = {
      session = {
        redis = {
          enabled = true
          host    = local.valkey_service_host
          port    = 6379
          password = {
            disabled = var.valkey_password == null
            value    = var.valkey_password != null ? var.valkey_password : ""
          }
        }
      }
    }
  }) : null

  # When Postgres is enabled, auto-wire Authelia's storage config.
  postgres_service_host = "db.${kubernetes_namespace_v1.authelia.metadata[0].name}.svc.cluster.local"

  db_authelia_values = local.postgres_enabled ? yamlencode({
    configMap = {
      storage = {
        local = { enabled = false }
        postgres = {
          enabled  = true
          address  = "tcp://${local.postgres_service_host}:5432"
          database = var.postgres_database_name
          username = var.postgres_user
          password = {
            disabled = false
            value    = var.postgres_password
          }
        }
      }
    }
    }) : yamlencode({
    configMap = {
      storage = {
        postgres = { enabled = false }
        local    = { enabled = true }
      }
    }
  })

  # When auth_backend is "lldap", auto-wire Authelia's LDAP authentication backend
  # using the built-in LLDAP implementation preset.
  lldap_authelia_values = var.auth_backend == "lldap" ? yamlencode({
    configMap = {
      authentication_backend = {
        ldap = {
          enabled        = true
          implementation = "lldap"
          address        = var.lldap_address
          base_dn        = var.lldap_base_dn
          user           = var.lldap_user
          password = {
            disabled = false
            value    = var.lldap_password
          }
        }
      }
    }
  }) : null

  # When auth_backend is "file", auto-wire Authelia's file authentication backend.
  # Creates a K8s Secret from the file_auth_users list and mounts it into the pod.
  file_auth_authelia_values = var.auth_backend == "file" ? yamlencode({
    configMap = {
      authentication_backend = {
        file = {
          enabled = true
          path    = "/config/users_database.yml"
          watch   = true
        }
      }
    }
    pod = {
      extraVolumes = [
        {
          name = "users-database"
          secret = {
            secretName = "authelia-users-db"
          }
        }
      ]
      extraVolumeMounts = [
        {
          name      = "users-database"
          mountPath = "/config/users_database.yml"
          subPath   = "users_database.yml"
          readOnly  = true
        }
      ]
    }
  }) : null
}

# Secret containing the users_database.yml for the file authentication backend.
# Only created when auth_backend is "file".
resource "kubernetes_secret_v1" "users_db" {
  count = var.auth_backend == "file" ? 1 : 0

  metadata {
    name      = "authelia-users-db"
    namespace = kubernetes_namespace_v1.authelia.metadata[0].name
  }

  lifecycle {
    precondition {
      condition     = length(var.file_auth_users) > 0
      error_message = "file_auth_users must not be empty when auth_backend is \"file\". Add a 'users' list to your sops file and pass it as file_auth_users."
    }
  }

  data = {
    "users_database.yml" = yamlencode({
      users = {
        for u in var.file_auth_users : u.username => {
          displayname = u.display_name
          password    = u.password
          email       = u.email
          groups      = u.groups
        }
      }
    })
  }
}

resource "helm_release" "valkey" {
  count = var.valkey_enabled ? 1 : 0

  name       = "valkey"
  repository = "https://valkey.io/valkey-helm/"
  chart      = "valkey"
  version    = var.valkey_chart_version
  namespace  = kubernetes_namespace_v1.authelia.metadata[0].name
  timeout    = var.timeout

  depends_on = [kubernetes_namespace_v1.authelia]

  values = concat(
    [yamlencode({
      dataStorage = {
        enabled       = var.valkey_storage_size != ""
        className     = var.valkey_storage_class
        requestedSize = var.valkey_storage_size
        accessModes   = ["ReadWriteOnce"]
      }
      auth = {
        enabled = var.valkey_password != null
      }
    })],
    var.valkey_password != null ? [yamlencode({
      auth = {
        aclUsers = {
          default = {
            permissions = "~* &* +@all"
            password    = var.valkey_password
          }
        }
      }
    })] : [],
  )
}

resource "helm_release" "authelia" {
  name       = "authelia"
  repository = "https://charts.authelia.com"
  chart      = "authelia"
  version    = var.chart_version
  namespace  = kubernetes_namespace_v1.authelia.metadata[0].name
  timeout    = var.timeout

  depends_on = [kubernetes_namespace_v1.authelia, kubernetes_secret_v1.users_db]

  values = concat(
    local.valkey_authelia_values != null ? [local.valkey_authelia_values] : [],
    local.lldap_authelia_values != null ? [local.lldap_authelia_values] : [],
    local.file_auth_authelia_values != null ? [local.file_auth_authelia_values] : [],
    [local.db_authelia_values],
    [var.helm_values],
    var.sensitive_values_yaml != null ? [var.sensitive_values_yaml] : [],
  )
}

# ReferenceGrant — allows ingress namespaces to route to the Authelia Service
resource "kubernetes_manifest" "traefik_httproute_service_grant" {
  for_each = toset(var.ingress_namespaces)

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1beta1"
    kind       = "ReferenceGrant"
    metadata = {
      name      = "allow-${each.value}-access"
      namespace = kubernetes_namespace_v1.authelia.metadata[0].name
    }
    spec = {
      from = [
        {
          group     = "gateway.networking.k8s.io"
          kind      = "HTTPRoute"
          namespace = each.value
        }
      ]
      to = [
        {
          group = ""
          kind  = "Service"
          name  = "authelia"
        }
      ]
    }
  }
}
