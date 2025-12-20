
resource "kubernetes_manifest" "traefik_httproute_service_grant" {
  for_each = toset(var.authelia_protected_namespaces)

  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1beta1"
    kind       = "ReferenceGrant"
    metadata = {
      name      = "allow-traefik-access"
      namespace = each.value
    }
    spec = {
      from = [
        {
          group     = "gateway.networking.k8s.io"
          kind      = "HTTPRoute"
          namespace = var.traefik_namespace
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

resource "kubernetes_manifest" "paperlessngx_http_route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind = "HTTPRoute"
    metadata = {
      name = "paperless-ngx"
      # namespace = "paperless-ngx"
      namespace = "traefik"
    }
    spec = {
      parentRefs = [
        {
          name = "traefik-gateway"
          namespace = var.traefik_namespace
        }
      ]
      hostnames = ["paperless.easontm.com"]
      rules = [
        {
          matches = [
            {
              path = {
                type = "PathPrefix"
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
              name = "webserver"
              kind = "Service"
              namespace = "paperless-ngx"
              port = 8000
            }
          ]
        }
      ]
    }
  }
}