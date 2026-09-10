# Installation de FOG Project

## Description

FOG Project est un serveur de déploiement d'images système open source, largement utilisé pour cloner, restaurer et déployer des postes de travail sur des machines physiques ou virtuelles. Il permet un déploiement rapide et centralisé des systèmes, avec gestion de l'imaging, de la capture d'images, de la restauration et du provisioning.

## Prérequis

- **Système d'exploitation** : Ubuntu 20.04 LTS ou plus récent / Debian 11+ / CentOS 8+ / Fedora / openSUSE / Arch Linux
- **Accès** : root ou sudo
- **Réseau** : connexion Internet stable, adresse IP fixe recommandée, ports réseau ouverts
- **Dépendances** : curl, wget, git, ca-certificates, tar, gzip
- **Ressources** : 2 Go de RAM minimum recommandés ; plus selon le nombre de machines à imager
- **Services réseau** : DHCP, TFTP, PXE, éventuellement NFS/SMB selon votre architecture

## Installation

### Méthode automatique (recommandée)

```bash
chmod +x install_fog_project.sh
bash install_fog_project.sh
```

### Installation manuelle (étapes détaillées)

#### 1. Mise à jour du système

```bash
sudo apt update && sudo apt upgrade -y  # Ubuntu/Debian
# ou
sudo dnf upgrade -y  # CentOS/RHEL/Fedora
# ou
sudo zypper update -y  # openSUSE
```

#### 2. Installation des dépendances de base

```bash
sudo apt install -y ca-certificates curl gnupg wget git tar gzip lsb-release  # Ubuntu/Debian
# ou
sudo dnf install -y ca-certificates curl gnupg wget git tar gzip  # CentOS/RHEL/Fedora
# ou
sudo zypper install -y ca-certificates curl gnupg wget git tar gzip  # openSUSE
```

#### 3. Préparation du serveur

Avant le déploiement FOG, il est recommandé de :

- attribuer une IP statique au serveur
- vérifier le bon fonctionnement du service DHCP
- prévoir un réseau PXE accessible
- préparer un accès web sur le port de gestion de FOG

#### 4. Téléchargement du code officiel FOG

```bash
cd /opt
sudo git clone https://github.com/FOGProject/fogproject.git
cd fogproject
```

#### 5. Lancement de l'installeur FOG

```bash
sudo bash bin/installfog.sh
```

> Le script officiel de FOG est généralement interactif. Il faudra valider les options du serveur (DHCP, PXE, web, stockage, etc.) selon votre architecture.

## Configuration

### Fichiers principaux

- `/opt/fogproject/` : code source du serveur FOG
- `/var/www/html/` : interface web et fichiers de gestion
- `/tftpboot/` : fichiers PXE et images de démarrage
- `/var/lib/tftpboot/` : fichiers TFTP de boot
- `/srv/fog/` : stockage principal des images et fichiers de déploiement

### Paramétrage recommandé

- utiliser une IP statique dédiée au serveur de déploiement
- sécuriser l'interface web avec HTTPS ou un reverse proxy
- configurer les options DHCP / PXE sur le réseau client
- préparer le stockage pour les images de postes
- effectuer un test de capture/restauration sur un poste de référence

## Ports requis

| Port | Protocole | Description |
|------|-----------|-------------|
| 80 | TCP | Interface web FOG |
| 443 | TCP | HTTPS / interface web sécurisée |
| 67 | UDP | DHCP |
| 69 | UDP | TFTP |
| 8080 | TCP | Interface alternative si configurée |
| 2049 | TCP/UDP | NFS (si utilisé) |

## Vérification

```bash
# Vérifier les services FOG / web / dhcp
sudo systemctl status apache2
sudo systemctl status dhcpd
sudo systemctl status tftpd-hpa

# Vérifier les ports
ss -tulpn | grep -E ':(80|443|67|69|8080|2049)'

# Vérifier le log du serveur FOG
sudo journalctl -u apache2 -n 50 --no-pager
```

### Test d'accès web

```bash
curl -I http://localhost
curl -I https://localhost
```

## Sécurité

- Limiter l'accès à l'interface web à des réseaux de confiance
- Utiliser HTTPS ou un reverse proxy devant FOG
- Ne pas exposer le service sans filtrage du réseau
- Gérer les droits d'accès et la séparation du stockage images
- Réaliser des sauvegardes régulières du stockage de données FOG

## Configuration du Firewall

### UFW

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 67/udp
sudo ufw allow 69/udp
sudo ufw status numbered
```

### firewalld

```bash
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=67/udp
sudo firewall-cmd --permanent --add-port=69/udp
sudo firewall-cmd --reload
```

## Dépannage

### Le serveur n'est pas accessible

```bash
sudo ss -tulpn | grep -E ':(80|443|67|69)'
sudo journalctl -n 100 --no-pager
```

### Le service DHCP / PXE ne démarre pas

```bash
sudo systemctl status dhcpd
sudo systemctl status tftpd-hpa
sudo journalctl -u dhcpd -n 100 --no-pager
```

### Les clients ne démarrent pas en PXE

```bash
# Vérifier la présence des fichiers de boot
ls -l /tftpboot/
ls -l /var/lib/tftpboot/

# Vérifier le réseau et les options DHCP
sudo tcpdump -i eth0 port 67 or port 68
```

## Documentation

- Site officiel FOG Project : https://fogproject.org/
- Documentation officielle : https://wiki.fogproject.org/
- Déploiement réseau / PXE : https://wiki.fogproject.org/wiki/index.php/FOG_Installation

## Notes

- FOG est avant tout un serveur de déploiement réseau. Il est essentiel d’avoir un bon plan de réseau, une IP fixe, des règles DHCP/PXE et un stockage suffisant.
- La meilleure manière de l’installer est souvent via le script officiel FOG, puis de valider le service sur un petit nombre de machines de test.
- En production, vérifiez bien la compatibilité de votre environnement avant d’imager des postes de travail importants.
