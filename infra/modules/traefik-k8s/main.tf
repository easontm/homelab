provider "helm" {
  kubernetes = {
    config_paths = var.kubeconfig_paths
  }
}

provider "kubernetes" {
  config_paths = var.kubeconfig_paths
}

# resource "kubernetes_cluster_role_v1" "traefik_gateway_role" {
#   metadata {
#     name = "gateway-role"
#   }
#   rule {
#     api_groups = [""]
#     resources  = ["namespaces"]
#     verbs      = ["list", "watch"]
#   }
#   rule {
#     api_groups = [""]
#     resources  = ["pods"]
#     verbs      = ["get"]
#   }
#   rule {
#     api_groups = [""]
#     resources  = ["services", "secrets", "configmaps"]
#     verbs      = ["get", "list", "watch"]
#   }
#   rule {
#     api_groups = ["discovery.k8s.io"]
#     resources  = ["endpointslices"]
#     verbs      = ["list", "watch"]
#   }
#   rule {
#     api_groups = ["gateway.networking.k8s.io"]
#     resources  = [
#         "gatewayclasses",
#         "gateways",
#         "httproutes",
#         "grpcroutes",
#         "tcproutes",
#         "tlsroutes",
#         "referencegrants",
#         "backendtlspolicies"
#     ]
#     verbs      = ["get", "list", "watch"]
#   }
#   rule {
#     api_groups = ["gateway.networking.k8s.io"]
#     resources  = [
#         "gatewayclasses/status",
#         "gateways/status",
#         "httproutes/status",
#         "grpcroutes/status",
#         "tcproutes/status",
#         "tlsroutes/status",
#         "referencegrants/status",
#         "backendtlspolicies/status"
#     ]
#     verbs      = ["update"]
#   }
#   rule {
#     api_groups = ["traefik.io"]
#     resources  = ["middlewares", "middlewares/status"]
#     verbs      = ["get", "list", "watch", "update"]
#   }
# }

# resource "kubernetes_service_account_v1" "traefik_gateway_service_account" {
#   metadata {
#     name      = "traefik-gateway-controller"
#     namespace = "traefik"
#   }
# }

# resource "kubernetes_cluster_role_binding_v1" "traefik_gateway_role_binding" {
#   metadata {
#     name = "gateway-controller"
#   }
#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = kubernetes_cluster_role_v1.traefik_gateway_role.metadata[0].name
#   }
#   subject {
#     kind      = "ServiceAccount"
#     name      = kubernetes_service_account_v1.traefik_gateway_service_account.metadata[0].name
#     namespace = kubernetes_service_account_v1.traefik_gateway_service_account.metadata[0].namespace
#   }
# }

# resource "kubernetes_secret_v1" "traefik_gateway_sa_token" {
#   metadata {
#     annotations = {
#       "kubernetes.io/service-account.name" = kubernetes_service_account_v1.traefik_gateway_service_account.metadata[0].name
#     }

#     # generate_name = "traefik-gateway-sa-token-"
#     name = "traefik-gateway-sa-token"
#     namespace = kubernetes_service_account_v1.traefik_gateway_service_account.metadata[0].namespace
#   }

#   type                           = "kubernetes.io/service-account-token"
#   wait_for_service_account_token = true
# }

# resource "kubernetes_manifest" "traefik_gateway_class" {
#   manifest = {
#     apiVersion = "gateway.networking.k8s.io/v1"
#     kind = "GatewayClass"
#     metadata = {
#       name = "traefik"
#     }
#     spec = {
#       controllerName = "traefik.io/gateway-controller"
#     }
#   }
# }

# resource "kubernetes_manifest" "traefik_gateway" {
#   manifest = {
#     apiVersion = "gateway.networking.k8s.io/v1"
#     kind = "Gateway"
#     metadata = {
#       name = "external-web"
#       namespace = "default"
#     }
#     spec = {
#       gatewayClassName = kubernetes_manifest.traefik_gateway_class.manifest["metadata"]["name"]
#       listeners = [
#         {
#           name = "http"
#           protocol = "HTTP"
#           port = 80
#           allowedRoutes = {
#             namespaces = {
#               from = "All"
#             }
#           }
#         },
#         # {
#         #   name = "https"
#         #   protocol = "HTTPS"
#         #   port = 443
#         #   allowedRoutes = {
#         #     namespaces = {
#         #       from = "All"
#         #     }
#         #   }
#         #   tls = {
#         #     mode = "Terminate"
#         #   }
#         # },
#       ]
#     }
#   }
# }

resource "helm_release" "traefik" {
  name       = "traefik"
  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  version    = var.chart_version
  namespace  = var.traefik_namespace
  timeout    = 120
  values     = [file("${path.module}/values.yaml")]

  
  # set = [
  #   {
  #     # Don't need the traefik pod
  #     name  = "deployment.enabled"
  #     value = false
  #   },
  #   {
  #     name  = "experimental.kubernetesGateway.enabled"
  #     value = true
  #   },
  #   {
  #     name  = "providers.kubernetesGateway.enabled"
  #     value = true
  #   },
  #   {
  #     # Will create a service (we don't need) for the pod that doesn't exist
  #     # and helm will hang because it defaults to a LoadBalancer (which I don't support)
  #     name  = "service.enabled"
  #     value = false
  #   },
  #   {
  #     name  = "gateway.listeners.web"
  #     value = {
  #       port     = 8000
  #       protocol = "HTTP"
  #       hostname = "*.easontm.com"
  #       namespacePolicy = {
  #         from = "All"
  #       }
  #     }
  #   }
  # ]
}

data "kubernetes_service_account_v1" "traefik_sa" {
  depends_on = [ helm_release.traefik ]
  metadata {
    name      = "traefik"
    namespace = var.traefik_namespace
  }
}


resource "kubernetes_secret_v1" "traefik_sa_token" {
  depends_on = [ helm_release.traefik ]
  metadata {
    annotations = {
      "kubernetes.io/service-account.name" = data.kubernetes_service_account_v1.traefik_sa.metadata[0].name
    }

    name = "traefik-sa-token"
    namespace = data.kubernetes_service_account_v1.traefik_sa.metadata[0].namespace
  }

  type                           = "kubernetes.io/service-account-token"
  wait_for_service_account_token = true
}



# This RG allows HTTPRoutes in other places to access the authelia middleware in the traefik namespace
# But HTTPRoutes can't use other middleware right now

# resource "kubernetes_manifest" "authelia_global_grant" {
#   manifest = {
#     apiVersion = "gateway.networking.k8s.io/v1beta1"
#     kind       = "ReferenceGrant"
#     metadata = {
#       name      = "authelia-global-access"
#       namespace = "traefik"
#     }
#     spec = {
#       from = [
#         for ns in var.authelia_protected_namespaces : {
#           group     = "gateway.networking.k8s.io"
#           kind      = "HTTPRoute"
#           namespace = ns
#         }
#       ]
#       to = [
#         {
#           group = "traefik.io"
#           kind  = "Middleware"
#           name  = "authelia"
#         }
#       ]
#     }
#   }
# }

