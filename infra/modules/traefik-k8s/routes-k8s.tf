#################
# Paperless-ngx
#################
# TODO: turn into a loop of objs
resource "kubernetes_manifest" "paperlessngx_http_route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "paperless-ngx"
      namespace = "traefik"
    }
    spec = {
      parentRefs = [
        {
          name      = "traefik-gateway"
          namespace = var.traefik_namespace
        }
      ]
      hostnames = ["paperless.${var.domain_name}"]
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
          filters = [
            {
              type = "ExtensionRef"
              extensionRef = {
                group = "traefik.io"
                kind  = "Middleware"
                name  = "authelia"
              }
            }
          ]
          backendRefs = [
            {
              name      = "webserver"
              kind      = "Service"
              namespace = "paperless-ngx"
              port      = 8000
            }
          ]
        }
      ]
    }
  }
}
