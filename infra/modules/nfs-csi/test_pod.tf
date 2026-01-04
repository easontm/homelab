resource "kubernetes_manifest" "smoke_test_pvc" {
  count      = var.test ? length(var.storage_classes) : 0
  depends_on = [helm_release.csi_driver_nfs]
  manifest = {
    apiVersion = "v1"
    kind       = "PersistentVolumeClaim"
    metadata = {
      name      = "nfs-test-pvc-${var.storage_classes[count.index].name}"
      namespace = "default"
    }
    spec = {
      storageClassName = var.storage_classes[count.index].name
      accessModes      = ["ReadWriteMany"]
      resources = {
        requests = {
          storage = "100Mi"
        }
      }
    }
  }
}

resource "kubernetes_pod_v1" "smoke_test_pod" {
  count      = var.test ? length(var.storage_classes) : 0
  depends_on = [kubernetes_manifest.smoke_test_pvc]
  metadata {
    name      = "nfs-test-pod-${var.storage_classes[count.index].name}"
    namespace = "default"
  }

  spec {
    container {
      name  = "nfs-test-container"
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
        claim_name = "nfs-test-pvc-${var.storage_classes[count.index].name}"
      }
    }

    restart_policy = "Never"
  }
}
