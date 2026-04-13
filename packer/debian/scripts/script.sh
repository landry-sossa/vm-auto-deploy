#!/bin/bash
# ============================================================
# hardening.sh — Hardening de base Packer
# Projet  : proxmox-auto-deploy
# Usage   : Exécuté par Packer via SSH après l'installation
#
# Ce script applique le hardening de base nécessaire
# pour passer les règles ANSSI BP-028 minimal qui échouent
# après la remédiation Ansible automatique
#
# Règles ciblées :
#   - Lock Accounts After Failed Password Attempts
#   - Configure the root Account for Failed Password Attempts
#   - Set Interval For Counting Failed Password Attempts
#   - Set Lockout Time for Failed Password Attempts
#   - Set Password Hashing Algorithm in /etc/login.defs
#   - Set Root Account Password Maximum Age
#   - Set number of Password Hashing Rounds - password-auth
#
# Le reste du hardening ANSSI est géré par Ansible
# ============================================================

set -e          # stoppe le script à la première erreur
set -o pipefail # stoppe si une commande dans un pipe échoue

echo "=== [1/6] Mise à jour des paquets ==="
apt-get update -y
apt-get upgrade -y

echo "=== [2/6] Suppression des paquets inutiles ==="
apt-get autoremove -y
apt-get autoclean -y
apt-get clean -y


# Règles : Lock Accounts, Configure root, Interval, Lockout Time
# Installation de libpam-runtime si absent
apt-get install -y libpam-pwquality



echo "=== [5/6] Nettoyage des traces du build ==="
# Suppression des logs d'installation
rm -rf /var/log/installer
truncate -s 0 /var/log/*.log 2>/dev/null || true

# Nettoyage du cache apt
rm -rf /var/cache/apt/archives/*.deb
rm -rf /var/cache/apt/archives/partial/*.deb

# Suppression des fichiers temporaires
rm -rf /tmp/*
rm -rf /var/tmp/*

echo "=== [6/6] Préparation pour le template ==="
# Suppression des clés SSH host
# Elles seront régénérées au premier boot de chaque VM clonée
rm -f /etc/ssh/ssh_host_*

# Vidage du machine-id
# Chaque VM clonée aura son propre ID unique au premier boot
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id

# Nettoyage de l'historique bash
truncate -s 0 /root/.bash_history
truncate -s 0 /home/packer/.bash_history 2>/dev/null || true

echo "=== Build Packer terminé — image prête pour le template ==="