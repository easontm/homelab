include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/kubernetes-crds"
}

inputs = {
  kubeconfig_paths = [
    "${get_terragrunt_dir()}/../traefik/.kube/config",
    "${get_env("HOME")}/.kube/config",
  ]
  bundle = "traefik/42.1.3"
  # force_conflicts_for = [
  #   "CustomResourceDefinition/ingressroutes.traefik.io",
  #   "CustomResourceDefinition/ingressroutetcps.traefik.io",
  #   "CustomResourceDefinition/ingressrouteudps.traefik.io",
  #   "CustomResourceDefinition/middlewares.traefik.io",
  #   "CustomResourceDefinition/middlewaretcps.traefik.io",
  #   "CustomResourceDefinition/serverstransports.traefik.io",
  #   "CustomResourceDefinition/serverstransporttcps.traefik.io",
  #   "CustomResourceDefinition/tlsoptions.traefik.io",
  #   "CustomResourceDefinition/tlsstores.traefik.io",
  #   "CustomResourceDefinition/traefikservices.traefik.io"
  # ]
}
