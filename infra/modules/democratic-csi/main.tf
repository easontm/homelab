provider "helm" {
  kubernetes = {
    config_paths = var.kubeconfig_paths
  }
}

provider "kubernetes" {
  config_paths = var.kubeconfig_paths
}

resource "helm_release" "democratic_csi" {
  name       = "democratic-csi"
  repository = "https://democratic-csi.github.io/charts/"
  chart      = "democratic-csi"
  version    = var.chart_version
  namespace  = var.namespace
  timeout    = 120
  values = [
    templatefile("${path.module}/values.yaml.tmpl", {
      truenas_host    = var.truenas_host
      truenas_api_key = var.truenas_api_key
      volume_path     = var.volume_path
      snapshot_path   = var.snapshot_path
      portal_group_id = tostring(var.portal_group_id)
      initiator_group_id = tostring(var.initiator_group_id)
    })
  ]
}
