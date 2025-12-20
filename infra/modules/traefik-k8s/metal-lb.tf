resource "helm_release" "metallb" {
  name       = "metallb"
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  # version    = "v1.19.2"
  namespace  = "metallb-system"
  create_namespace = true
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
      addresses = ["192.168.1.240-192.168.1.253"]
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