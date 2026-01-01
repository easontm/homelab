# cert-manager must be installed, and so must its cluster-issuer
resource "kubernetes_manifest" "traefik_certificate" {
  count = local.use_origin_cert ? 0 : 1
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "traefik-dummy-cert"
      namespace = var.traefik_namespace
    }
    spec = {
      secretName = "gateway-dummy-tls"
      commonName = var.common_name
      dnsNames   = var.dns_names
      issuerRef = {
        name = "selfsigned"
        kind = "ClusterIssuer"
      }
    }
  }
}

resource "kubernetes_manifest" "cloudflare_origin_ca_cert" {
  count = local.use_origin_cert ? 1 : 0
  manifest = {
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "cloudflare-origin-cert"
      namespace = var.traefik_namespace
    }
    type = "kubernetes.io/tls"
    data = {
      "tls.crt" = base64encode(var.cloudflare_origin_ca_cert)
      "tls.key" = base64encode(var.cloudflare_origin_ca_key)
    }
  }
}
