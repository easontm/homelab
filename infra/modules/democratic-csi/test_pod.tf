resource "kubernetes_manifest" "smoke_test_pvc" {
  count      = var.test ? 1 : 0
  depends_on = [helm_release.democratic_csi]
  manifest = {
    apiVersion = "v1"
    kind       = "PersistentVolumeClaim"
    metadata = {
      name      = "iscsi-test-pvc"
      namespace = "default"
      annotations = {
        "volume.beta.kubernetes.io/storage-class" = var.storage_class_name
      }
    }
    spec = {
      storageClassName = var.storage_class_name
      accessModes      = ["ReadWriteOnce"]
      resources = {
        requests = {
          storage = "100Mi"
        }
      }
    }
  }
}

resource "kubernetes_pod_v1" "smoke_test_pod" {
  count      = var.test ? 1 : 0
  depends_on = [kubernetes_manifest.smoke_test_pvc]
  metadata {
    name      = "iscsi-test-pod"
    namespace = "default"
  }

  spec {
    container {
      name  = "iscsi-test-container"
      image = "busybox"

      command = [
        "sh",
        "-c",
        "echo ok > /data/test && sleep 30"
      ]

      volume_mount {
        name       = "data"
        mount_path = "/data"
      }
    }

    volume {
      name = "data"

      persistent_volume_claim {
        claim_name = "iscsi-test-pvc"
      }
    }

    restart_policy = "Never"
  }
}
