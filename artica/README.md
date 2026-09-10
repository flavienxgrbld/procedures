# Installation d'Artica

## Description

Artica est une solution d'administration et de surveillance réseau, souvent utilisée comme proxy web, filtre de contenu, ou outil de gestion centralisée de services et de sécurité applicative. Dans le cadre de cette procédure, la logique d'installation suit le même principe que les autres scripts du dépôt : préparation du système, ajout du dépôt officiel si disponible, installation du service, activation, puis vérification.

## Prérequis

- **Système d'exploitation** : Ubuntu 20.04 LTS ou plus récent / Debian 11+ / CentOS 8+ / Fedora / openSUSE / Arch Linux
- **Accès** : root ou sudo
- **Réseau** : connexion Internet active pour télécharger les paquets et les fichiers d'installation
- **Ressources** : 2 Go de RAM minimum recommandés, espace disque selon l'usage (proxy, filtre, logs, etc.)
- **Ports** : ports Web, proxy et gestion à prévoir selon l'architecture

## Installation

### Méthode automatique (recommandée)

```bash
chmod +x install_artica.sh
bash install_artica.sh
```

### Installation manuelle (étapes détaillées)

#### 1. Mise à jour du système

```bash
sudo apt update && sudo apt upgrade -y  # Ubuntu/Debian
# ou
sudo dnf update -y  # CentOS/RHEL/Fedora
# ou
sudo zypper update -y  # openSUSE
```

#### 2. Installation des dépendances de base

```bash
sudo apt install -y ca-certificates curl gnupg wget lsb-release git  # Ubuntu/Debian
# ou
sudo dnf install -y ca-certificates curl gnupg wget git  # CentOS/RHEL/Fedora
# ou
sudo zypper install -y ca-certificates curl gnupg wget git  # openSUSE
```

#### 3. Ajout du dépôt officiel Artica

```bash
# Exemple de configuration classique ; adapter selon le dépôt officiel disponible pour votre distribution.
curl -fsSL https://download.artica.fr/artica.gpg | sudo gpg --dearmor -o /usr/share/keyrings/artica-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/artica-archive-keyring.gpg] https://download.artica.fr/ stable main" | sudo tee /etc/apt/sources.list.d/artica.list > /dev/null

sudo apt update
```

> La clé et l'URL de dépôt peuvent varier selon les versions et les distributions. Vérifiez toujours la documentation officielle avant de déployer en production.

#### 4. Installation du paquet Artica

```bash
sudo apt install -y artica
```

#### 5. Démarrage du service

```bash
sudo systemctl enable --now artica
sudo systemctl status artica
```

## Configuration

### Fichiers de configuration principaux

- `/etc/artica/` : configuration générale
- `/etc/systemd/system/` : service système
- `/var/log/artica/` : logs applicatifs
- `/var/lib/artica/` : données de l'application

### Paramétrage recommandé

- Créer un certificat TLS pour l'interface admin
- Configurer les règles de filtrage et de proxy
- Vérifier les ACL réseau et les règles de sécurité
- Configurer les règles d'accès admin uniquement depuis des réseaux fiables

## Ports requis

| Port | Protocole | Description |
|------|-----------|-------------|
| 80 | TCP | HTTP |
| 443 | TCP | HTTPS |
| 3128 | TCP | Proxy HTTP |
| 8080 | TCP | Interface web si utilisée |
| 8443 | TCP | HTTPS admin alternat. |

## Vérification

```bash
# Vérifier le service
sudo systemctl status artica

# Vérifier les ports
ss -tulpn | grep -E ':(80|443|3128|8080|8443)'

# Voir les logs
sudo journalctl -u artica -n 100 --no-pager
```

### Test de l'interface

```bash
curl -I http://localhost
curl -I https://localhost
```

## Sécurité

- Ne pas exposer l'interface d'administration sur Internet sans filtrage
- Utiliser HTTPS et un certificat valide
- Limiter les accès admin aux IPs de confiance
- Sauvegarder la configuration régulièrement
- Mettre à jour le système et Artica dès que des correctifs sont disponibles

## Configuration du Firewall

### UFW

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3128/tcp
sudo ufw allow 8080/tcp
sudo ufw allow 8443/tcp
sudo ufw status numbered
```

### firewalld

```bash
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=3128/tcp
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=8443/tcp
sudo firewall-cmd --reload
```

## Dépannage

### Le service ne démarre pas

```bash
sudo journalctl -u artica -n 200 --no-pager
sudo systemctl restart artica
```

### Port déjà utilisé

```bash
sudo ss -tulpn | grep :3128
sudo lsof -i :3128
```

### Problème d'accès web

```bash
sudo tail -n 200 /var/log/artica/*.log
sudo systemctl status artica
```

## Documentation

- Documentation officielle Artica : https://www.artica.fr/
- Documentation proxy / sécurité web : https://www.gnu.org/software/gnu-c-coding-standards/
- Documentation Linux système : https://wiki.debian.org/

## Notes

- Artica est souvent déployé dans une architecture réseau dédiée ; son installation doit tenir compte des règles de filtrage, de proxy et des éventuels certificats TLS.
- Avant mise en production, validez la configuration sur un environnement de test avec une vraie topologie réseau.
- Les URL de dépôt peuvent varier selon la version et la distribution ; vérifiez toujours la documentation officielle pendant l'installation.
