provider "helm" {
  kubernetes = {
    config_paths = var.kubeconfig_paths
  }
}

provider "kubernetes" {
  config_paths = var.kubeconfig_paths
}

resource "helm_release" "csi_driver_nfs" {
  name       = "csi-driver-nfs"
  repository = "https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts"
  chart      = "csi-driver-nfs"
  version    = var.chart_version
  namespace  = var.namespace
  timeout    = 120
  values = [
    templatefile("${path.module}/values.yaml.tmpl", {
      storage_class_name = var.storage_class_name
      nfs_server         = var.nfs_server
      nfs_path           = var.nfs_path
    })
  ]
}
