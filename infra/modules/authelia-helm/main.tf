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

  depends_on = [kubernetes_namespace_v1.authelia]

  values = concat(
    [for f in var.values_files : file(f)],
    local.valkey_authelia_values != null ? [local.valkey_authelia_values] : [],
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
