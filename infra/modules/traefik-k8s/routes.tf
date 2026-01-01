# TODO: ReferenceGrants should be managed by the modules allowing Traefik.
resource "kubernetes_manifest" "traefik_httproute_service_grant" {
  for_each = toset(var.traefik_granted_namespaces)

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
              port = 9091
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
          port       = 9091
          targetPort = 9091
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
        addresses = [{ ip = "192.168.1.103" }]
        ports     = [{ port = 9091 }]
      }
    ]
  }
}
