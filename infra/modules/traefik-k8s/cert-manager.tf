resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "oci://quay.io/jetstack/charts"
  chart      = "cert-manager"
  version    = "v1.19.2"
  namespace  = "cert-manager"
  create_namespace = true
  timeout    = 30
  set = [
    {
      name  = "crds.enabled"
      value = true
    }
  ]
}

resource "kubernetes_manifest" "cluster_issuer" {
  depends_on = [ helm_release.cert_manager ]
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "selfsigned"
    }
    spec = {
      selfSigned: {}
    }
  }
}

resource "kubernetes_manifest" "traefik_certificate" {
  depends_on = [ helm_release.cert_manager, kubernetes_manifest.cluster_issuer ]
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