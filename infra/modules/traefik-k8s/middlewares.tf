
resource "kubernetes_manifest" "authelia_middleware" {
  depends_on = [ helm_release.traefik ]
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind = "Middleware"
    metadata = {
      name = "authelia"
      namespace = var.traefik_namespace
    }
    spec = {
      forwardAuth = {
        address = "http://192.168.1.103:9091/api/authz/forward-auth"
        trustForwardHeader = true
        authResponseHeaders = [
          "Remote-User",
          "Remote-Groups",
          "Remote-Email",
          "Remote-Name"
        ]
      }
    }
  }
}

resource "kubernetes_manifest" "test_middleware" {
  depends_on = [ helm_release.traefik ]
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind = "Middleware"
    metadata = {
      name = "test-headers"
      namespace = var.traefik_namespace
      annotations = {
        "kubernetes.io/ingress.class" = "traefik"
      }
    }
    spec = {
      headers = {
        customRequestHeaders = {
          X-Test = "true"
        }
      }
    }
  }
}