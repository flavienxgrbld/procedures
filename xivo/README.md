# Installation de XiVO

## Description

XiVO est une solution de téléphonie IP / PBX open source basée sur Asterisk, conçue pour gérer les appels, les utilisateurs, les groupes, les files d'attente et l'administration centralisée d'un environnement vocal.

## Prérequis

- **Système d'exploitation** : Ubuntu 20.04 LTS ou plus récent / Debian 11+ / CentOS 8+ / Fedora / openSUSE / Arch Linux
- **Accès** : root ou sudo
- **Réseau** : connexion Internet stable et ports réseau ouverts
- **Dépendances** : curl, wget, gnupg, git, et service système
- **Ressources** : 2 Go de RAM minimum recommandés pour une installation légère, davantage selon le nombre d'utilisateurs et de lignes SIP

## Installation

### Méthode automatique (recommandée)

```bash
chmod +x install_xivo.sh
bash install_xivo.sh
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
sudo apt install -y ca-certificates curl gnupg wget lsb-release git  # Ubuntu/Debian
# ou
sudo dnf install -y ca-certificates curl gnupg wget git  # CentOS/RHEL/Fedora
# ou
sudo zypper install -y ca-certificates curl gnupg wget git  # openSUSE
```

#### 3. Ajout du dépôt officiel XiVO

```bash
# Exemple de configuration classique pour les distributions Debian/Ubuntu
curl -fsSL https://apt.xivo.io/xivo-release.gpg | sudo gpg --dearmor -o /usr/share/keyrings/xivo-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/xivo-archive-keyring.gpg] https://apt.xivo.io/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/xivo.list > /dev/null

sudo apt update
```

> Si le dépôt officiel a changé ou si l'URL de votre distribution diffère, adaptez-la en fonction de la documentation de votre environnement.

#### 4. Installation du paquet XiVO

```bash
sudo apt install -y xivo
```

#### 5. Démarrage et activation du service

```bash
sudo systemctl enable --now xivo
sudo systemctl status xivo
```

## Configuration

### Fichiers de configuration principaux

- `/etc/xivo/` : configuration générale XiVO
- `/etc/asterisk/` : configuration Asterisk
- `/var/log/xivo/` : logs de l'application
- `/var/lib/xivo/` : données de l'instance

### Paramétrage réseau et voix

- Vérifier les interfaces réseau et la configuration de l'IP statique
- Configurer les trunks SIP ou ISDN selon le besoin
- Vérifier le bon fonctionnement des codecs et des numéros externes
- Créer les utilisateurs, groupes, files d'attente et plans de numérotation

## Ports requis

| Port | Protocole | Description |
|------|-----------|-------------|
| 80 | TCP | Web admin (si activé) |
| 443 | TCP | HTTPS admin |
| 5060 | UDP/TCP | SIP |
| 5061 | TCP | SIP sécurisé |
| 10000-20000 | UDP | RTP / voix |

## Vérification

```bash
# Vérifier l'état du service
sudo systemctl status xivo

# Vérifier les ports ouverts
ss -tulpn | grep -E ':(80|443|5060|5061|10000)'

# Vérifier les logs
sudo journalctl -u xivo -n 100 --no-pager
```

### Test rapide

```bash
curl -I http://localhost
curl -I https://localhost
```

## Sécurité

- Limiter l'accès admin à l'IP du bureau ou au VPN
- Activer HTTPS / TLS si possible
- Utiliser des mots de passe forts pour les comptes admin
- Vérifier les règles du firewall
- Mettre à jour régulièrement le système et les paquets

## Configuration du Firewall

### UFW

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 5060/tcp
sudo ufw allow 5060/udp
sudo ufw allow 5061/tcp
sudo ufw allow 10000:20000/udp
sudo ufw status numbered
```

### firewalld

```bash
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --permanent --add-port=5060/udp
sudo firewall-cmd --permanent --add-port=5060/tcp
sudo firewall-cmd --permanent --add-port=5061/tcp
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" port port="10000-20000" protocol="udp" accept'
sudo firewall-cmd --reload
```

## Dépannage

### Le service ne démarre pas

```bash
sudo journalctl -u xivo -n 200 --no-pager
sudo systemctl restart xivo
```

### Port SIP déjà utilisé

```bash
sudo ss -tulpn | grep :5060
sudo lsof -i :5060
```

### Asterisk ne répond pas correctement

```bash
sudo asterisk -rvvv
core show channels
pjsip show endpoints
```

## Documentation

- Site officiel XiVO : https://xivo.io/
- Documentation Asterisk : https://www.asterisk.org/
- Guide de déploiement SIP : https://www.rfc-editor.org/

## Notes

- XiVO est une solution de téléphonie, donc il faut tenir compte du plan de numérotation, des droits d'accès et de la sécurité des flux SIP.
- Faites toujours un test en environnement de préproduction avant un déploiement complet.
- En production, veillez à la qualité de service réseau ainsi qu'aux sauvegardes régulières.
