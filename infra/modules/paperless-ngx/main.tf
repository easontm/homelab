provider "kubernetes" {
  config_paths = var.kubeconfig_paths
}

# Namespace
resource "kubernetes_namespace_v1" "paperless_ngx" {
  metadata {
    name = var.namespace
  }
}

# Secret for database password
resource "kubernetes_secret_v1" "db_secret" {
  metadata {
    name      = "db-secret"
    namespace = kubernetes_namespace_v1.paperless_ngx.metadata[0].name
  }

  data = {
    POSTGRES_PASSWORD = var.postgres_password
  }
}

resource "kubernetes_manifest" "traefik_httproute_service_grant" {
  for_each = toset(var.ingress_namespaces)

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1beta1"
    kind       = "ReferenceGrant"
    metadata = {
      name      = "allow-${each.value}-access"
      namespace = var.namespace
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
          name  = "webserver"
        }
      ]
    }
  }
}