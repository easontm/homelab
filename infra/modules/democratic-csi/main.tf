provider "helm" {
  kubernetes = {
    config_paths = var.kubeconfig_paths
  }
}

provider "kubernetes" {
  config_paths = var.kubeconfig_paths
}

resource "kubernetes_namespace_v1" "democratic_csi" {
  metadata {
    name = var.csi_namespace

    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "helm_release" "snapshot_controller" {
  name       = "snapshot-controller"
  repository = "https://democratic-csi.github.io/charts/"
  chart      = "snapshot-controller"
  version    = var.snapshot_chart_version
  namespace  = var.snapshot_controller_namespace
  timeout    = 120
}

resource "helm_release" "democratic_csi" {
  depends_on = [helm_release.snapshot_controller]
  name       = "democratic-csi"
  repository = "https://democratic-csi.github.io/charts/"
  chart      = "democratic-csi"
  version    = var.csi_chart_version
  namespace  = var.csi_namespace
  timeout    = 120
  values = [
    templatefile("${path.module}/values.yaml.tmpl", {
      truenas_host       = var.truenas_host
      truenas_api_key    = var.truenas_api_key
      storage_class_name = var.storage_class_name
      volume_path        = var.volume_path
      snapshot_path      = var.snapshot_path
      portal_group_id    = tostring(var.portal_group_id)
      initiator_group_id = tostring(var.initiator_group_id)
    })
  ]
}
