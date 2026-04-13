# VM Auto Deploy

Pipeline complet pour le déploiement automatisé et la mise
en conformité ANSSI BP-028 de machines virtuelles Debian 12 sur
Proxmox VE.

## Architecture

Packer → Terraform → Ansible + OpenSCAP → GitHub Actions

- **Packer** construit une golden image Debian 12
- **Terraform** déploie les VMs depuis le template
- **Ansible + OpenSCAP** applique la conformité ANSSI BP-028
- **GitHub Actions** orchestre l'ensemble automatiquement

## Documentation

La documentation complète est disponible sur :
[landry-sossa.github.io/homelab-proxmox-doc](https://landry-sossa.github.io/homelab-proxmox-doc)

## Prérequis

- Proxmox VE opérationnel
- Windows ou Linux comme machine de développement
- ISO Debian 12 netinst uploadée sur Proxmox
- Compte GitHub avec un dépôt privé pour les tests

## Installation rapide

### 1. Cloner le dépôt

```bash
git clone https://github.com/landry-sossa/vm-auto-deploy.git
cd proxmox-auto-deploy
```

### 2. Créer les fichiers de configuration

```bash
# Packer
cp packer/debian/debian.pkrvars.hcl.example \
   packer/debian/debian.pkrvars.hcl

# Terraform
cp terraform/terraform.tfvars.example \
   terraform/terraform.tfvars

# Pipeline
cp pipeline/config.yml.example \
   pipeline/config.yml
```

### 3. Remplir les fichiers de configuration

Éditez chaque fichier avec vos valeurs. Consultez la documentation
pour le détail de chaque paramètre.

### 4. Générer la paire de clés SSH

```bash
# Linux / WSL
ssh-keygen -t rsa -b 4096 \
  -f ~/.ssh/packer_id_rsa \
  -C "packer@build" -N ""

# Windows PowerShell
ssh-keygen -t rsa -b 4096 `
  -f "$HOME\.ssh\packer_id_rsa" `
  -C "packer@build" -N ""
```

### 5. Utilisation locale

#### Packer — Construire le template

```bash
cd packer/debian
packer init .
packer validate -var-file="debian.pkrvars.hcl" debian.pkr.hcl
packer build -var-file="debian.pkrvars.hcl" debian.pkr.hcl
```

#### Terraform — Déployer une VM

```bash
cd terraform
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

#### Ansible — Appliquer la conformité ANSSI

```bash
cd ansible
ansible -i inventory/hosts.yml debian_vms -m ping
ansible-playbook -i inventory/hosts.yml playbooks/compliance.yml
```

### 6. Utilisation via le pipeline GitHub Actions

Configurez les secrets dans votre dépôt GitHub :

Settings → Secrets and variables → Actions

| Secret | Description |
|--------|-------------|
| `PROXMOX_URL` | URL de l'API Proxmox |
| `PROXMOX_USERNAME` | Utilisateur Packer |
| `PROXMOX_TOKEN` | Secret du token Packer |
| `TERRAFORM_API_TOKEN` | Token Terraform complet |
| `ISO_CHECKSUM` | Checksum SHA512 de l'ISO |
| `PACKER_SSH_PUBLIC_KEY` | Clé publique SSH |
| `PACKER_SSH_PRIVATE_KEY` | Clé privée SSH |

Puis poussez sur main :

```bash
git add .
git commit -m "feat: déploiement initial"
git push origin main
```

Le pipeline se déclenche automatiquement.

## Structure du projet

## Licence

Ce projet est distribué sous licence MIT.
Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## Auteur

Landry SOSSA 