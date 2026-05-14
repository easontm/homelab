resource "kubernetes_manifest" "k8s_http_route" {
  for_each = var.k8s_service_routes

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = each.key
      namespace = var.traefik_namespace
    }
    spec = {
      parentRefs = [
        {
          name      = "traefik-gateway"
          namespace = var.traefik_namespace
        }
      ]
      hostnames = ["${each.value.subdomain}.${var.domain_name}"]
      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/"
              }
            }
          ]
          filters = each.value.auth ? [
            {
              type = "ExtensionRef"
              extensionRef = {
                group = "traefik.io"
                kind  = "Middleware"
                name  = "authelia"
              }
            }
          ] : []
          backendRefs = [
            {
              name      = each.value.service
              kind      = "Service"
              namespace = each.value.namespace
              port      = each.value.port
            }
          ]
        }
      ]
    }
  }
}
