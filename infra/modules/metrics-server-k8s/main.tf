provider "helm" {
  kubernetes = {
    config_paths = var.kubeconfig_paths
  }
}
provider "kubernetes" {
  config_paths = var.kubeconfig_paths
}

resource "helm_release" "metrics_server" {
  name             = "metrics-server"
  repository       = "https://kubernetes-sigs.github.io/metrics-server/"
  chart            = "metrics-server"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = false
  timeout          = 120
  values = [
    templatefile("${path.module}/values.yaml.tmpl", {})
  ]
}
