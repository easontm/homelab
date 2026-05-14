provider "kubernetes" {
  config_paths = var.kubeconfig_paths
}

# Namespace
resource "kubernetes_namespace_v1" "homebox" {
  metadata {
    name = var.namespace
  }
}

# ReferenceGrant — allows ingress namespaces to route to the homebox Service
resource "kubernetes_manifest" "traefik_httproute_service_grant" {
  for_each = toset(var.ingress_namespaces)

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1beta1"
    kind       = "ReferenceGrant"
    metadata = {
      name      = "allow-${each.value}-access"
      namespace = kubernetes_namespace_v1.homebox.metadata[0].name
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
          name  = "homebox"
        }
      ]
    }
  }
}
