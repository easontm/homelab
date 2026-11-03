# Generated once and retained in state; shared by the webserver and exporter.
resource "random_password" "paperless_secret_key" {
  length  = 64
  special = false
}

resource "kubernetes_secret_v1" "paperless" {
  metadata {
    name      = "paperless-secret"
    namespace = kubernetes_namespace_v1.paperless_ngx.metadata[0].name
  }

  data = {
    PAPERLESS_SECRET_KEY = random_password.paperless_secret_key.result
  }
}
