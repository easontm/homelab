provider "helm" {
  kubernetes = {
    config_paths = var.kubeconfig_paths
  }
}

provider "kubernetes" {
  config_paths = var.kubeconfig_paths
}


resource "helm_release" "metallb" {
  name       = "metallb"
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  namespace  = var.namespace
  create_namespace = false
  version    = var.chart_version
  timeout    = 60
}

resource "kubernetes_manifest" "ip_address_pool" {
  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "IPAddressPool"
    metadata = {
      name      = "lan-pool"
      namespace = helm_release.metallb.namespace
    }
    spec = {
      addresses = var.ip_ranges
    }
  }
}

resource "kubernetes_manifest" "l2_advertisement" {
  manifest = {
    apiVersion = "metallb.io/v1beta1"
    kind       = "L2Advertisement"
    metadata = {
      name      = "lan"
      namespace = helm_release.metallb.namespace
    }
    spec = {
      ipAddressPools = [kubernetes_manifest.ip_address_pool.manifest.metadata.name]
    }
  }
}