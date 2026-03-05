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

#################
# Authelia
#################
resource "kubernetes_manifest" "authelia_http_route" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "authelia"
      namespace = var.traefik_namespace
    }
    spec = {
      parentRefs = [
        {
          name      = "traefik-gateway"
          namespace = var.traefik_namespace
        }
      ]
      hostnames = ["auth.${var.domain_name}"]
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
          backendRefs = [
            {
              name = "authelia-external"
              kind = "Service"
              port = local.authelia_service_port
            }
          ]
        }
      ]
    }
  }
}


resource "kubernetes_manifest" "authelia_service" {
  depends_on = [helm_release.traefik]
  manifest = {
    apiVersion = "v1"
    kind       = "Service"
    metadata = {
      name      = "authelia-external"
      namespace = var.traefik_namespace
    }
    spec = {
      ports = [
        {
          port       = local.authelia_service_port
          targetPort = local.authelia_service_port
          protocol   = "TCP"
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "authelia_endpoint" {
  depends_on = [helm_release.traefik]
  manifest = {
    apiVersion = "v1"
    kind       = "Endpoints"
    metadata = {
      name      = "authelia-external"
      namespace = var.traefik_namespace
    }
    subsets = [
      {
        # TODO: parameterize
        addresses = [{ ip = split(":", var.authelia_service_url)[0] }]
        ports     = [{ port = local.authelia_service_port }]
      }
    ]
  }
}
