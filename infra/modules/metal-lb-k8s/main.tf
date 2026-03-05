provider "helm" {
  kubernetes = {
    config_paths = var.kubeconfig_paths
  }
}

provider "kubernetes" {
  config_paths = var.kubeconfig_paths
}


resource "kubernetes_namespace_v1" "metallb" {
  metadata {
    name = var.namespace

    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
}

resource "helm_release" "metallb" {
  depends_on       = [kubernetes_namespace_v1.metallb]
  name             = "metallb"
  repository       = "https://metallb.github.io/metallb"
  chart            = "metallb"
  namespace        = var.namespace
  create_namespace = false
  version          = var.chart_version
  timeout          = 180
}

resource "kubernetes_manifest" "ip_address_pool" {
  depends_on = [helm_release.metallb]
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
  depends_on = [helm_release.metallb]
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
