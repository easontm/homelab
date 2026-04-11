resource "kubernetes_manifest" "external_http_route" {
  for_each = var.external_service_urls

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
          backendRefs = [
            {
              name = "${each.key}-external"
              kind = "Service"
              port = tonumber(split(":", each.value.url)[1])
            }
          ]
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "external_service" {
  for_each   = var.external_service_urls
  depends_on = [helm_release.traefik]

  manifest = {
    apiVersion = "v1"
    kind       = "Service"
    metadata = {
      name      = "${each.key}-external"
      namespace = var.traefik_namespace
    }
    spec = {
      ports = [
        {
          port       = tonumber(split(":", each.value.url)[1])
          targetPort = tonumber(split(":", each.value.url)[1])
          protocol   = "TCP"
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "external_endpoint" {
  for_each   = var.external_service_urls
  depends_on = [helm_release.traefik]

  manifest = {
    apiVersion = "v1"
    kind       = "Endpoints"
    metadata = {
      name      = "${each.key}-external"
      namespace = var.traefik_namespace
    }
    subsets = [
      {
        addresses = [{ ip = split(":", each.value.url)[0] }]
        ports     = [{ port = tonumber(split(":", each.value.url)[1]) }]
      }
    ]
  }
}
