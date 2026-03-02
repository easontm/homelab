output "controlplane_nodes" {
  description = "List of control plane node IPs"
  value       = [for k, v in var.node_data.controlplanes : k]
}

output "worker_nodes" {
  description = "List of worker node IPs"
  value       = [for k, v in var.node_data.workers : k]
}

output "kubeconfig" {
  description = "Kubeconfig for the Talos cluster"
  sensitive   = true
  value       = talos_cluster_kubeconfig.this.kubeconfig_raw
}

output "talosctl_config" {
  description = "Talosctl client configuration"
  sensitive   = true
  value       = data.talos_client_configuration.this.talos_config
}
