# VM Auto Deploy

Pipeline complet pour le déploiement automatisé et la mise
en conformité ANSSI BP-028 de machines virtuelles Debian 12 sur
Proxmox VE.
<div align="center">
  
![Proxmox VE](https://img.shields.io/badge/Proxmox_VE-E57000?style=for-the-badge&logo=proxmox&logoColor=white)
![Packer](https://img.shields.io/badge/Packer-02A8EF?style=for-the-badge&logo=packer&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-844FBA?style=for-the-badge&logo=terraform&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=for-the-badge&logo=ansible&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)
![Debian](https://img.shields.io/badge/Debian-A81D33?style=for-the-badge&logo=debian&logoColor=white)

</div>
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

#### Packer - Construire le template

```bash
cd packer/debian
packer init .
packer validate -var-file="debian.pkrvars.hcl" debian.pkr.hcl
packer build -var-file="debian.pkrvars.hcl" debian.pkr.hcl
```

#### Terraform - Déployer une VM

```bash
cd terraform
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

#### Ansible - Appliquer la conformité ANSSI

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

```md id="w9pxfj"
## Roadmap

### Fonctionnalités actuelles
- [x] Déploiement automatique de VM Debian sur Proxmox
- [x] Configuration initiale automatisée
- [x] Publication du projet en open source

### Évolutions prévues
- [ ] Ajouter le support Ubuntu
- [ ] Ajouter le support CentOS / RedHat
- [ ] Améliorer la sécurité des VM déployées
- [ ] Ajouter le support d'autres environnements de virtualisation
- [ ] Préparer une extension vers des environnements cloud
- [ ] Ajouter une documentation plus détaillée
```


## Structure du projet

## Licence

Ce projet est distribué sous licence MIT.
Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## Auteur

Landry SOSSA 


