# ============================================================
# variables.tf — Déclaration des variables
# Projet  : proxmox-auto-deploy
# ============================================================

# --- Connexion Proxmox ---
variable "proxmox_endpoint" {
  type        = string
  description = "URL complète de l'API Proxmox"
}

variable "proxmox_api_token" {
  type        = string
  description = "Token API format user@realm!tokenid=secret"
  sensitive   = true
}

variable "proxmox_ip" {  
  type        = string
  description = "IP de proxmox"
  sensitive   = true
}

variable "proxmox_node" {
  type        = string
  description = "Nom du nœud Proxmox"
  default     = "pve"
}

# --- Template source ---
variable "template_vm_id" {
  type        = number
  description = "ID du template Packer à cloner"
  default     = 9000
}

# --- VM déployée ---
variable "vm_id" {
  type        = number
  description = "ID de la VM déployée"
  default     = 100
}

variable "vm_name" {
  type        = string
  description = "Nom de la VM"
  default     = "debian-vm-01"
}

variable "vm_cores" {
  type        = number
  description = "Nombre de cœurs CPU"
  default     = 1
}

variable "vm_memory" {
  type        = number
  description = "RAM en MB"
  default     = 2048
}

variable "vm_disk_size" {
  type        = number
  description = "Taille du disque en GB"
  default     = 20
}

variable "vm_storage_pool" {
  type        = string
  description = "Storage Proxmox pour le disque VM"
  default     = "local-lvm"
}

variable "vm_bridge" {
  type        = string
  description = "Bridge réseau Proxmox"
  default     = "vmbr1"
}

variable "vm_tags" {
  type        = list(string)
  description = "Tags Proxmox pour la VM"
  default     = ["terraform", "debian-12"]
}

# --- Réseau cloud-init ---
variable "ip_config_type" {
  type        = string
  description = "Type d'adressage : static ou dhcp"
  default     = "static"

  validation {
    condition     = contains(["static", "dhcp"], var.ip_config_type)
    error_message = "ip_config_type doit être 'static' ou 'dhcp'."
  }
}

variable "vm_ip_address" {
  type        = string
  description = "Adresse IP statique avec masque ex: 10.10.0.10/24"
  default     = ""
}

variable "vm_gateway" {
  type        = string
  description = "Gateway du réseau"
  default     = ""
}

variable "vm_dns" {
  type        = string
  description = "Serveur DNS"
  default     = "1.1.1.1"
}

# --- cloud-init utilisateur ---
variable "admin_username" {
  type        = string
  description = "Nom du user admin créé par cloud-init"
  default     = "packer"
}

variable "ssh_public_key" {
  type        = string
  description = "Clé publique SSH pour le user admin"
  sensitive   = true
}