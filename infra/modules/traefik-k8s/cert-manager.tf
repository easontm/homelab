# cert-manager must be installed, and so must its cluster-issuer
resource "kubernetes_manifest" "traefik_certificate" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "traefik-dummy-cert"
      namespace = var.traefik_namespace
    }
    spec = {
      secretName = "gateway-dummy-tls"
      commonName = "*.easontm.com"
      dnsNames   = ["*.easontm.com"]
      issuerRef = {
        name = "selfsigned"
        kind = "ClusterIssuer"
      }
    }
  }
}
