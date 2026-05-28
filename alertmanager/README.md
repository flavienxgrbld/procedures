# Installation d'Alertmanager

## Description

Alertmanager - Gestionnaire d'alertes pour Prometheus

### Type
Monitoring

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
chmod +x install_alertmanager.sh

# 2. Exécutez le script d'installation
bash install_alertmanager.sh

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
- **alertmanager** — service système avec démarrage automatique

## Ports requis

| Port | Protocole | Description |
|------|-----------|-------------|
| 9093 | TCP       | Interface Alertmanager |

## Configuration

### Configuration de base

Les fichiers de configuration se trouvent généralement dans :
- `/etc/alertmanager/` — configuration de l'application
- `/etc/systemd/system/` — services systemd
- `/var/lib/alertmanager/` — données de l'application
- `/var/log/alertmanager/` — logs de l'application

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

# Vérifier Alertmanager
systemctl status alertmanager

# Vérifier l'activation au démarrage
systemctl is-enabled alertmanager
```

### Vérifier les ports
```bash
# Afficher les ports en écoute
ss -tlnp
# ou
netstat -tlnp

# Vérifier un port spécifique
ss -tlnp | grep :9093
```

### Logs et debugging
```bash
# Logs en temps réel
journalctl -u alertmanager -f

# Derniers logs
journalctl -u alertmanager -n 50

# Tous les logs
journalctl -u alertmanager
```

### Test d'accès web
```bash
# Vérifier la connectivité HTTP
curl -v http://localhost:9093

# Ou via navigateur
# http://votre-serveur:9093
```

## Configuration du firewall

### Avec UFW (Debian/Ubuntu)
```bash
# Autoriser le port
sudo ufw allow 9093/tcp

# Vérifier les règles
sudo ufw status numbered
```

### Avec firewall-cmd (RedHat/Fedora)
```bash
# Autoriser le port
sudo firewall-cmd --permanent --add-port=9093/tcp

# Recharger
sudo firewall-cmd --reload
```

## Dépannage

### Problèmes courants

#### Le service ne démarre pas
```bash
# Vérifier les erreurs
sudo journalctl -u alertmanager -n 50

# Vérifier la version
alertmanager --version

# Redémarrer
sudo systemctl restart alertmanager

# Permissions
sudo chown -R alertmanager:alertmanager /var/lib/alertmanager/
```

#### Port déjà utilisé
```bash
# Identifier le processus
sudo ss -tlnp | grep :9093

# Ou
sudo lsof -i :9093

# Tuer le processus
sudo kill -9 PID

# Redémarrer
sudo systemctl restart alertmanager
```

#### Permissions insuffisantes
```bash
# Ajouter au groupe
sudo usermod -aG alertmanager $USER

# Permissions
sudo chown -R alertmanager:alertmanager /var/lib/alertmanager/

# Reconnexion
exit
```

#### Firewall bloque l'accès
```bash
# Vérifier
sudo ufw status

# Autoriser
sudo ufw allow 9093/tcp

# Tester
curl -v http://localhost:9093
```

### Vérification des logs système
```bash
# Debian/Ubuntu
tail -f /var/log/syslog

# RedHat/Fedora
tail -f /var/log/messages

# Logs applicatifs
tail -f /var/log/alertmanager/*.log
```

### Réinitialisation complète
```bash
# Stop
sudo systemctl stop alertmanager

# Disable
sudo systemctl disable alertmanager

# Suppression
sudo rm -rf /opt/alertmanager
sudo rm -rf /var/lib/alertmanager
sudo rm -rf /etc/alertmanager

# Service
sudo rm /etc/systemd/system/alertmanager.service
sudo systemctl daemon-reload

# Réinstallation
bash install_alertmanager.sh
```

## Documentation officielle

- Site officiel : https://prometheus.io/
- Documentation : https://prometheus.io/docs/alerting/latest/alertmanager/
- GitHub : https://github.com/prometheus/alertmanager

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
sudo tar -czf backup-alertmanager-$(date +%Y%m%d).tar.gz /var/lib/alertmanager/

# Restauration
sudo tar -xzf backup-alertmanager-YYYYMMDD.tar.gz -C /
```

### Mise à jour
```bash
# Vérifier
apt list --upgradable

# Mettre à jour
sudo apt upgrade alertmanager

# Redémarrer
sudo systemctl restart alertmanager
```

### Restauration configuration
```bash
# Backup
sudo cp /etc/alertmanager/config.yml /etc/alertmanager/config.yml.bak

# Réinstallation
sudo apt install --reinstall alertmanager
```

## Intégrations possibles
- Nginx / Apache / HAProxy
- Prometheus / Grafana
- ELK / Loki
- Docker / Kubernetes

---

**Dernière mise à jour** : 03/05/2026  
**Version du script** : 1.0  
**Statut** : Production Ready ✅