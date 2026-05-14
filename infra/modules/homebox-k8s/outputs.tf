output "namespace" {
  description = "Kubernetes namespace where Homebox is deployed"
  value       = kubernetes_namespace_v1.homebox.metadata[0].name
}

output "service_name" {
  description = "Kubernetes Service name for Homebox"
  value       = kubernetes_service_v1.homebox.metadata[0].name
}

output "cluster_ip" {
  description = "ClusterIP assigned to the Homebox Service"
  value       = kubernetes_service_v1.homebox.spec[0].cluster_ip
}
