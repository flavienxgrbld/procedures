# Installation de dnsmasq

## Description

Dnsmasq est un serveur léger combinant les fonctionnalités DNS, DHCP et TFTP, souvent utilisé pour les réseaux locaux et les environnements embarqués.

### Type
Serveur réseau

## Prérequis

- **Système d'exploitation** : Ubuntu 20.04 LTS ou plus récent / Debian 11+ / CentOS 8+ / Fedora / openSUSE / Arch Linux
- **Accès** : accès root ou sudo
- **Ressources** : faible consommation (RAM ≥ 1 Go recommandé)
- **Réseau** : connexion Internet stable
- **Ports** : ports DNS/DHCP disponibles
- **Dépendances** : curl, wget, git (installés automatiquement si nécessaire)

## Installation

### Méthode automatique (recommandée)

```bash
# 1. Rendez le script exécutable
chmod +x install_dnsmasq.sh

# 2. Exécutez le script d'installation
bash install_dnsmasq.sh

# 3. Répondez aux questions interactives si nécessaire
```

### Installation manuelle (étapes détaillées)

#### 1. Mise à jour du système
```bash
sudo apt update && sudo apt upgrade -y  # Debian/Ubuntu
# ou
sudo dnf update -y  # RedHat/Fedora
# ou
sudo zypper update  # openSUSE
```

#### 2. Installation de dnsmasq
```bash
sudo apt install dnsmasq -y
```

#### 3. Activation du service
```bash
sudo systemctl enable dnsmasq
sudo systemctl start dnsmasq
```

## Configuration

### Fichiers principaux
- `/etc/dnsmasq.conf` — configuration principale
- `/etc/dnsmasq.d/` — configurations additionnelles
- `/var/lib/misc/dnsmasq.leases` — baux DHCP

### Exemple de configuration basique
```bash
sudo nano /etc/dnsmasq.conf
```

Exemple :
```
interface=eth0
dhcp-range=192.168.1.100,192.168.1.200,12h
domain-needed
bogus-priv
```

Redémarrage :
```bash
sudo systemctl restart dnsmasq
```

## Vérification de l'installation

### Vérifier le service
```bash
systemctl status dnsmasq
systemctl is-enabled dnsmasq
```

### Vérifier les ports
```bash
ss -tulpn | grep dnsmasq
```

Ports utilisés :
- 53 TCP/UDP (DNS)
- 67 UDP (DHCP)

### Logs
```bash
journalctl -u dnsmasq -f
```

## Configuration du firewall

### UFW (Debian/Ubuntu)
```bash
sudo ufw allow 53/tcp
sudo ufw allow 53/udp
sudo ufw allow 67/udp
```

### firewall-cmd (RedHat/Fedora)
```bash
sudo firewall-cmd --permanent --add-port=53/tcp
sudo firewall-cmd --permanent --add-port=53/udp
sudo firewall-cmd --permanent --add-port=67/udp
sudo firewall-cmd --reload
```

## Dépannage

### Service ne démarre pas
```bash
sudo journalctl -u dnsmasq -n 50
sudo dnsmasq --test
```

### Port déjà utilisé
```bash
sudo ss -tulpn | grep :53
sudo lsof -i :53
```

### Redémarrage propre
```bash
sudo systemctl restart dnsmasq
```

## Vérification DNS
```bash
nslookup google.com
dig google.com
```

## Documentation
- Site officiel : https://thekelleys.org.uk/dnsmasq/doc.html
- Man page : `man dnsmasq`

## Notes
- dnsmasq est très léger et adapté aux réseaux locaux
- Ne pas exposer directement sur Internet sans filtrage
- Idéal pour les réseaux internes, VM et containers