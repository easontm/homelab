provider "helm" {
  kubernetes = {
    config_paths = var.kubeconfig_paths
  }
}

provider "kubernetes" {
  config_paths = var.kubeconfig_paths
}

resource "helm_release" "traefik" {
  name       = "traefik"
  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  version    = var.chart_version
  namespace  = var.traefik_namespace
  timeout    = 120
  values     = [file("${path.module}/values.yaml")]
}

data "kubernetes_service_account_v1" "traefik_sa" {
  depends_on = [helm_release.traefik]
  metadata {
    name      = "traefik"
    namespace = var.traefik_namespace
  }
}


resource "kubernetes_secret_v1" "traefik_sa_token" {
  depends_on = [helm_release.traefik]
  metadata {
    annotations = {
      "kubernetes.io/service-account.name" = data.kubernetes_service_account_v1.traefik_sa.metadata[0].name
    }

    name      = "traefik-sa-token"
    namespace = data.kubernetes_service_account_v1.traefik_sa.metadata[0].namespace
  }

  type                           = "kubernetes.io/service-account-token"
  wait_for_service_account_token = true
}
