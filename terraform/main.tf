# ============================================================
# main.tf — Provider + Ressource VM
# Projet  : proxmox-auto-deploy
# Provider : bpg/proxmox
# Landry SOSSA
# ============================================================

###############################################################
# BLOC 1 — Provider
###############################################################
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.66.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = true   # certificat auto-signé homelab

  # Requis par bpg/proxmox pour certaines opérations
  # comme la gestion des snippets cloud-init
  ssh {
    agent = false
    node {
      name    = var.proxmox_node
      address = var.proxmox_ip
    }
  }
}

###############################################################
# BLOC 2 — Ressource VM
# Clone le template Packer et configure via cloud-init
###############################################################
resource "proxmox_virtual_environment_vm" "debian_vm" {

  # --- Identité ---
  name      = var.vm_name
  node_name = var.proxmox_node
  vm_id     = var.vm_id
  tags      = sort(var.vm_tags)

  description = "VM Debian 12 — déployée par Terraform — ${timestamp()}"

  # --- Clone depuis le template Packer ---
  clone {
    vm_id = var.template_vm_id
    full  = true   # clone complet — pas de dépendance au template
  }

  # --- Agent QEMU ---
  # Permet à Proxmox de récupérer l'IP de la VM
  agent {
    enabled = true
  }

  # --- CPU ---
  cpu {
    cores = var.vm_cores
    type  = "x86-64-v2-AES"
  }

  # --- RAM ---
  memory {
    dedicated = var.vm_memory
  }

  # --- Disque ---
  # On redéfinit le disque hérité du clone
  # pour s'assurer de la bonne taille et config
  disk {
    datastore_id = var.vm_storage_pool
    interface    = "scsi0"
    size         = var.vm_disk_size
    file_format  = "raw"
    discard      = "on"
    iothread     = true
    cache        = "none"
  }

  # --- Réseau ---
  network_device {
    bridge = var.vm_bridge
    model  = "virtio"
  }

  # --- Cloud-init ---
  # Injecte la configuration au premier boot
  initialization {

    # IP statique ou DHCP selon la variable ip_config_type
    ip_config {
      ipv4 {
        address = var.ip_config_type == "static" ? var.vm_ip_address : "dhcp"
        gateway = var.ip_config_type == "static" ? var.vm_gateway : null
      }
    }

    # DNS
    dns {
      servers = [var.vm_dns]
    }

    # Utilisateur admin + clé SSH
    user_account {
      username = var.admin_username
      keys     = [trimspace(var.ssh_public_key)]
    }
  }

  # --- Démarrage ---
  started       = true
  on_boot       = false  # ne démarre pas automatiquement avec Proxmox

  # --- Timeout ---
  # Clone complet peut prendre du temps
  timeout_clone = 300
}