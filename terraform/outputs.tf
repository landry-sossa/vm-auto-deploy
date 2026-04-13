# ============================================================
# outputs.tf — Informations affichées après terraform apply
# ============================================================

output "vm_id" {
  description = "ID de la VM créée"
  value       = proxmox_virtual_environment_vm.debian_vm.vm_id
}

output "vm_name" {
  description = "Nom de la VM créée"
  value       = proxmox_virtual_environment_vm.debian_vm.name
}

output "vm_ip_address" {
  description = "Adresse IP de la VM"
  value       = var.ip_config_type == "static" ? var.vm_ip_address : "DHCP — voir Proxmox"
}

output "vm_node" {
  description = "Nœud Proxmox hébergeant la VM"
  value       = proxmox_virtual_environment_vm.debian_vm.node_name
}

output "ssh_connection" {
  description = "Commande SSH pour se connecter"
  value       = "ssh -i ~/.ssh/packer_id_rsa ${var.admin_username}@${var.ip_config_type == "static" ? split("/", var.vm_ip_address)[0] : "IP-DHCP"}"
}