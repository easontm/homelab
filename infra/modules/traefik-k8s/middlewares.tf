#################
# Authelia
#################
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


#################
# Secure Headers
#################
resource "kubernetes_manifest" "secure_headers_middleware" {
  depends_on = [ helm_release.traefik ]
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind = "Middleware"
    metadata = {
      name = "secure-headers"
      namespace = var.traefik_namespace
    }
    spec = {
      headers = {
        sslRedirect = true
        stsSeconds = 31536000
        stsIncludeSubdomains = true
        stsPreload = true
        contentTypeNosniff = true
        browserXssFilter = true
        referrerPolicy = "no-referrer"
        permissionsPolicy = "geolocation=()"
        customResponseHeaders = {
          X-Frame-Options = "DENY"
          X-Content-Type-Options = "nosniff"
          X-XSS-Protection = "1; mode=block"
          Cache-Control = "no-store"
        }
      }
    }
  }
}
