provider "helm" {
  kubernetes = {
    config_paths = var.kubeconfig_paths
  }
}

provider "kubernetes" {
  config_paths = var.kubeconfig_paths
}


resource "kubernetes_namespace_v1" "velero" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "velero" {
  depends_on       = [kubernetes_namespace_v1.velero]
  name             = "velero"
  repository       = "https://vmware-tanzu.github.io/helm-charts"
  chart            = "velero"
  namespace        = var.namespace
  create_namespace = false
  version          = var.chart_version
  timeout          = 180
  values = [
    templatefile("${path.module}/values.yaml.tmpl", {
      aws_access_key_id     = var.key_id
      aws_secret_access_key = var.secret_key
    })
  ]
}
