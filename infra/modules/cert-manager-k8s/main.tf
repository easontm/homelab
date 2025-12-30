provider "helm" {
  kubernetes = {
    config_paths = var.kubeconfig_paths
  }
}
provider "kubernetes" {
  config_paths = var.kubeconfig_paths
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "oci://quay.io/jetstack/charts"
  chart      = "cert-manager"
  version    = var.chart_version
  namespace  = var.namespace
  create_namespace = false
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
