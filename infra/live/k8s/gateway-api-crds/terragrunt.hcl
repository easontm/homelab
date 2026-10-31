include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/kubernetes-crds"
}

inputs = {
  # Share Traefik's cluster config; CRDs are cluster-scoped, not namespaced.
  kubeconfig_paths = [
    "${get_terragrunt_dir()}/../traefik/.kube/config",
    "${get_env("HOME")}/.kube/config",
  ]
  bundle = "gateway-api/1.6.3-standard"
  # force_conflicts_for = ["CustomResourceDefinition/backendtlspolicies.gateway.networking.k8s.io", "CustomResourceDefinition/gatewayclasses.gateway.networking.k8s.io", "CustomResourceDefinition/gateways.gateway.networking.k8s.io", "CustomResourceDefinition/grpcroutes.gateway.networking.k8s.io", "CustomResourceDefinition/referencegrants.gateway.networking.k8s.io"]
}
