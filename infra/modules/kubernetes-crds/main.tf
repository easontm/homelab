terraform {
  required_version = ">= 1.10.6"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 3.0.1, < 4.0.0"
    }
  }
}

provider "kubernetes" {
  config_paths = var.kubeconfig_paths
}

locals {
  documents = [
    for filename in fileset("${path.module}/manifests/${var.bundle}", "*.yaml") :
    yamldecode(file("${path.module}/manifests/${var.bundle}/${filename}"))
  ]
  manifests = {
    for document in local.documents :
    "${document.kind}/${document.metadata.name}" => document
  }
}

# Includes the Gateway API bundle's admission policy and binding, not just CRDs.
resource "kubernetes_manifest" "resource" {
  for_each = local.manifests

  manifest = each.value

  field_manager {
    name            = "homelab-crds"
    force_conflicts = contains(var.force_conflicts_for, each.key)
  }

  dynamic "wait" {
    for_each = each.value.kind == "CustomResourceDefinition" ? [true] : []
    content {
      condition {
        type   = "Established"
        status = "True"
      }
    }
  }

  timeouts {
    create = "5m"
    update = "5m"
  }

  lifecycle {
    # CRD deletion would also delete the custom resources stored under it.
    prevent_destroy = true
  }
}
