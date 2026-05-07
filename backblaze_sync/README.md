# Installation de backblaze_sync

## Description

SyncThing - Synchronisation P2P décentralisée

### Type
Application

## Prérequis

- **Système d'exploitation** : Ubuntu 20.04 LTS ou plus récent / Debian 11+ / CentOS 8+ / Fedora / openSUSE / Arch Linux
- **Accès** : accès root ou sudo
- **Ressources** : RAM minimale 2 Go, espace disque selon l'application
- **Réseau** : connexion Internet stable
- **Ports** : ports disponibles pour l'application
- **Dépendances** : curl, wget, git (installés automatiquement si nécessaire)

## Installation

### Méthode automatique (recommandée)

```bash
# 1. Rendez le script exécutable
chmod +x install_backblaze_sync.sh

# 2. Exécutez le script d'installation
bash install_backblaze_sync.sh

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

#### 2. Installation des dépendances de base
```bash
sudo apt install -y build-essential curl wget git  # Debian/Ubuntu
```

#### 3. Vérification du gestionnaire de paquets
Le script détecte automatiquement votre système et utilise le bon gestionnaire parmi :
- **apt** (Debian, Ubuntu)
- **dnf/yum** (Red Hat, Fedora, CentOS)
- **zypper** (openSUSE)
- **pacman** (Arch Linux)

#### 4. Installation des packages
L'installation inclut automatiquement :
- Toutes les dépendances requises
- Les services système
- La configuration de base
- Les autorisations firewall

## Services installés

Les services suivants seront créés et activés :
- **syncthing@root** — service système avec démarrage automatique

## Ports requis

| Port | Protocole | Description |
|------|-----------|-------------|
| 21025 | TCP       | Synchronisation |

## Configuration

### Configuration de base

Les fichiers de configuration se trouvent généralement dans :
- `/etc/backblaze_sync/` — configuration de l'application
- `/etc/systemd/system/` — services systemd
- `/var/lib/backblaze_sync/` — données de l'application
- `/var/log/backblaze_sync/` — logs de l'application

### Configuration avancée

Consultez la documentation officielle pour :
- Configuration SSL/TLS
- Intégration avec d'autres services
- Optimisation des performances
- Haute disponibilité

## Vérification de l'installation

### Vérifier l'état des services
```bash
# Vérifier tous les services
systemctl status

# Vérifier le service principal
systemctl status syncthing@root

# Vérifier l'activation au démarrage
systemctl is-enabled syncthing@root
```

### Vérifier les ports
```bash
# Afficher les ports en écoute
ss -tlnp
# ou
netstat -tlnp

# Vérifier un port spécifique
ss -tlnp | grep :21025
```

### Logs et debugging
```bash
# Logs en temps réel
journalctl -u syncthing@root -f

# Derniers logs
journalctl -u syncthing@root -n 50

# Tous les logs
journalctl -u syncthing@root
```

### Test d'accès web
```bash
# Vérifier la connectivité HTTP (si interface web activée)
curl -v http://localhost:8384

# Ou via navigateur
# http://votre-serveur:8384
```

## Configuration du firewall

### Avec UFW (Debian/Ubuntu)
```bash
# Autoriser le port
sudo ufw allow 21025/tcp

# Vérifier les règles
sudo ufw status numbered
```

### Avec firewall-cmd (RedHat/Fedora)
```bash
# Autoriser le port
sudo firewall-cmd --permanent --add-port=21025/tcp

# Recharger
sudo firewall-cmd --reload
```

## Dépannage

### Problèmes courants

#### Le service ne démarre pas
```bash
# Vérifier les erreurs
sudo journalctl -u syncthing@root -n 50

# Vérifier la version
syncthing --version

# Redémarrer
sudo systemctl restart syncthing@root

# Permissions
sudo chown -R $(whoami):$(whoami) /var/lib/backblaze_sync/
```

#### Port déjà utilisé
```bash
# Identifier le processus
sudo ss -tlnp | grep :21025

# Ou
sudo lsof -i :21025

# Tuer le processus
sudo kill -9 PID

# Redémarrer
sudo systemctl restart syncthing@root
```

#### Permissions insuffisantes
```bash
# Ajouter au groupe
sudo usermod -aG syncthing $USER

# Permissions
sudo chown -R syncthing:syncthing /var/lib/backblaze_sync/

# Reconnexion
exit
```

#### Firewall bloque l'accès
```bash
# Vérifier
sudo ufw status

# Autoriser
sudo ufw allow 21025/tcp

# Tester
curl -v http://localhost:8384
```

### Vérification des logs système
```bash
# Debian/Ubuntu
tail -f /var/log/syslog

# RedHat/Fedora
tail -f /var/log/messages

# Logs applicatifs
tail -f /var/log/backblaze_sync/*.log
```

### Réinitialisation complète
```bash
# Stop
sudo systemctl stop syncthing@root

# Disable
sudo systemctl disable syncthing@root

# Suppression
sudo rm -rf /opt/backblaze_sync
sudo rm -rf /var/lib/backblaze_sync
sudo rm -rf /etc/backblaze_sync

# Service
sudo rm /etc/systemd/system/syncthing@root.service
sudo systemctl daemon-reload

# Réinstallation
bash install_backblaze_sync.sh
```

## Documentation officielle

- Site officiel : https://syncthing.net/
- Documentation : https://docs.syncthing.net/
- GitHub : https://github.com/syncthing/syncthing

## Notes supplémentaires

### Sécurité
1. Utiliser HTTPS en production
2. Configurer le firewall correctement
3. Utiliser des mots de passe forts
4. Mettre à jour régulièrement
5. Faire des sauvegardes
6. Limiter les accès
7. Utiliser des certificats SSL valides

### Optimisation
1. Limiter les ressources
2. Ajuster le cache
3. Utiliser un load balancer
4. Surveiller les métriques
5. Optimiser le stockage

### Sauvegarde
```bash
# Sauvegarde
sudo tar -czf backup-backblaze_sync-$(date +%Y%m%d).tar.gz /var/lib/backblaze_sync/

# Restauration
sudo tar -xzf backup-backblaze_sync-YYYYMMDD.tar.gz -C /
```

### Mise à jour
```bash
# Vérifier
apt list --upgradable

# Mettre à jour
sudo apt upgrade backblaze_sync

# Redémarrer
sudo systemctl restart syncthing@root
```

### Restauration configuration
```bash
# Backup
sudo cp /etc/backblaze_sync/config /etc/backblaze_sync/config.bak

# Réinstallation
sudo apt install --reinstall backblaze_sync
```

## Intégrations possibles
- Nginx / Apache / HAProxy
- Prometheus / Grafana
- ELK / Loki
- Docker / Kubernetes

---

**Dernière mise à jour** : 03/05/2026  
**Version du script** : 1.0  
**Testé sur** : apt (Debian/Ubuntu), dnf/yum (RedHat/Fedora)  
**Statut** : Production Ready ✅