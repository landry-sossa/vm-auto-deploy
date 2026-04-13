# ============================================================
# debian.pkr.hcl — Golden Image Debian 12 Bookworm
# Projet  : proxmox-auto-deploy
# Builder : proxmox-iso
# landry SOSSA
# ============================================================

###############################################################
# BLOC 1 — Plugin
###############################################################
packer {
  required_plugins {
    proxmox = {
      version = ">= 1.2.1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

###############################################################
# BLOC 2 — Variables
###############################################################

# --- Connexion Proxmox ---
variable "proxmox_url" {
  type        = string
  description = "URL complète de l'API Proxmox"
}

variable "proxmox_username" {
  type        = string
  description = "Utilisateur Proxmox format user@realm!tokenid"
}

variable "proxmox_token" {
  type        = string
  description = "Token API Proxmox — ne jamais mettre en dur"
  sensitive   = true
}

variable "proxmox_node" {
  type        = string
  description = "Nom du nœud Proxmox cible"
  default     = "pve"
}

# --- VM ---
variable "vm_id" {
  type        = number
  description = "ID unique du template dans Proxmox (100-999999999)"
  default     = 9000
}

variable "vm_name" {
  type        = string
  description = "Nom du template dans Proxmox"
  default     = "debian-12-golden"
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
  type        = string
  description = "Taille du disque principal"
  default     = "20G"
}

variable "vm_storage_pool" {
  type        = string
  description = "Storage Proxmox pour le disque VM"
  default     = "local-lvm"
}

variable "vm_bridge" {
  type        = string
  description = "Bridge réseau Proxmox"
  default     = "vmbr0"
}

variable "vm_profile" {
  type        = string
  description = "Profil de partitionnement : base | webserver | database"
  default     = "base"
}

# --- ISO ---
variable "iso_file" {
  type        = string
  description = "Chemin exact de l'ISO dans Proxmox"
  default     = "local:iso/debian-12.13.0-amd64-DVD-1.iso"
}

variable "iso_checksum" {
  type        = string
  description = "Checksum SHA512 de l'ISO — récupéré depuis cdimage.debian.org"
}

# --- Localisation ---
variable "locale" {
  type        = string
  description = "Locale système"
  default     = "fr_FR.UTF-8"
}

variable "timezone" {
  type        = string
  description = "Fuseau horaire"
  default     = "Europe/Paris"
}

variable "keyboard" {
  type        = string
  description = "Disposition clavier"
  default     = "fr"
}

# --- Accès SSH ---
variable "ssh_username" {
  type        = string
  description = "Utilisateur SSH créé pendant le build"
  default     = "packer"
}

variable "ssh_public_key" {
  type        = string
  description = "Clé publique SSH — contenu de packer_id_rsa.pub"
  sensitive   = true
}

variable "bind_address" {
  type        = string
  description = "Adresse IP de la machine Windows pour le serveur HTTP de Packer"
}

###############################################################
# BLOC 3 — Source
###############################################################
source "proxmox-iso" "debian-12" {

  # --- Authentification Proxmox ---
  proxmox_url = var.proxmox_url
  username    = var.proxmox_username
  token       = var.proxmox_token
  # true car ton Proxmox homelab utilise un certificat auto-signé
  insecure_skip_tls_verify = true

  # --- Nœud et identité ---
  node    = var.proxmox_node
  vm_id   = var.vm_id
  vm_name = var.vm_name
  tags    = "debian-12;template;golden"

  # --- Ressources ---
  cores   = var.vm_cores
  sockets = 1
  memory  = var.vm_memory
  os      = "l26"

  # --- ISO de boot ---
  boot_iso {
    type         = "scsi"
    iso_file     = var.iso_file
    iso_checksum = var.iso_checksum
    unmount      = true
  }

  # --- Disque principal ---
  disks {
    type         = "scsi"
    disk_size    = var.vm_disk_size
    storage_pool = var.vm_storage_pool
    format       = "raw"
    discard      = true
    io_thread    = true
  }

  # virtio-scsi-single requis pour io_thread = true
  scsi_controller = "virtio-scsi-single"

  # --- Réseau ---
  network_adapters {
    model    = "virtio"
    bridge   = var.vm_bridge
    firewall = false
  }

  # --- Agent QEMU ---
  qemu_agent = true

  # --- Cloud-init ---
  # Drive vide ajouté au template
  # Terraform injectera ses données au déploiement
  cloud_init              = true
  cloud_init_storage_pool = var.vm_storage_pool

  # --- Preseed via templatefile ---
  # On utilise http_content au lieu de http_directory
  # pour injecter la clé SSH publique dynamiquement
  # sans la mettre en dur dans le fichier preseed
  http_content = {
    "/preseed.cfg" = templatefile("${path.root}/http/preseed.cfg.pkrtpl", {
      ssh_public_key = var.ssh_public_key
      timezone       = var.timezone
      locale         = var.locale
      keyboard       = var.keyboard
    })
  }
  # On force Packer à utiliser ta carte Wi-Fi au lieu de WSL ou VMware
  http_bind_address = var.bind_address

  http_port_min = 8100
  http_port_max = 8200

  # --- Boot ---
  boot_wait = "10s"

  boot_command = [
    "<esc><wait>",
    "auto ",
    "url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg ",
    "console-keymaps-at/keymap=fr ",
    "console-setup/ask_detect=false ",
    "debconf/frontend=noninteractive ",
    "fb=false ",
    "<enter>"
  ]

  # --- Connexion SSH post-install ---
  communicator         = "ssh"
  ssh_username         = var.ssh_username
  ssh_private_key_file = "~/.ssh/packer_id_rsa"
  ssh_timeout          = "15m"

  # --- Template final ---
  template_name        = var.vm_name
  template_description = "Debian 12.13.0 Golden Image — Packer — profil: ${var.vm_profile} — ${formatdate("YYYY-MM-DD", timestamp())}"
}

###############################################################
# BLOC 4 — Build
###############################################################
build {
  name    = "debian-12-golden"
  sources = ["source.proxmox-iso.debian-12"]

  # --- Étape 1 : vérification connexion ---
  provisioner "shell" {
    inline = [
      "echo '=== Packer connecté ==='",
      "uname -a",
      "whoami",
      "ip addr show"
    ]
  }

  # --- Étape 2 : script minimal ---
  provisioner "shell" {
    script          = "scripts/script.sh"
    execute_command = "sudo bash '{{ .Path }}'"
  }



}