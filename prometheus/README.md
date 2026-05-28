# Installation de prometheus

## Description

Prometheus - Système de monitoring et de collecte de métriques

### Type
Monitoring

## Prérequis

- **Système d'exploitation** : Ubuntu 20.04 LTS ou plus récent / Debian 11+ / CentOS 8+ / Fedora / openSUSE / Arch Linux
- **Accès** : Accès root ou sudo
- **Ressources** : RAM minimale 2GB, espace disque selon l'application
- **Réseau** : Connexion Internet stable
- **Port** : Ports disponibles pour l'application
- **Dépendances** : curl, wget, git (installés automatiquement si nécessaire)

## Installation

### Méthode Automatique (Recommandée)

`ash
# 1. Rendez le script exécutable
chmod +x install_prometheus.sh

# 2. Exécutez le script d'installation
bash install_prometheus.sh

# 3. Répondez aux questions interactives si nécessaire
`

### Étapes Manuelles Détaillées

#### 1. Mise à jour du système
`ash
sudo apt update && sudo apt upgrade -y  # Debian/Ubuntu
# ou
sudo dnf update -y  # RedHat/Fedora
# ou
sudo zypper update  # openSUSE
`

#### 2. Installation des dépendances de base
`ash
sudo apt install -y build-essential curl wget git  # Debian/Ubuntu
`

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

## Services Installés

Les services suivants seront créés et activés :
- **prometheus** - Service système avec démarrage automatique

## Ports Requis

| Port | Protocole | Description |
|------|-----------|-------------|

| 9090 | tcp | Prometheus Web UI |
## Configuration

### Configuration de Base

Les fichiers de configuration se trouvent généralement dans :
- /etc/prometheus/ - Configuration de l'application
- /etc/systemd/system/ - Configuration des services
- /var/lib/prometheus/ - Données de l'application
- /var/log/prometheus/ - Logs de l'application

### Configuration Avancée

Consultez la documentation officielle pour :
- Configuration SSL/TLS
- Intégration avec d'autres services
- Optimisation des performances
- Haute disponibilité

## Vérification de l'Installation

### Vérifier l'état des services
`ash
# Vérifier tous les services
systemctl status

# Vérifier les services spécifiques
systemctl status prometheus
# Vérifier que le service démarre au boot
systemctl is-enabled True
`

### Vérifier les ports
`ash
# Afficher les ports écoutants
ss -tlnp
# ou
netstat -tlnp

# Vérifier un port spécifique
ss -tlnp | grep :$PORT_NUMBER
`

### Logs et Debugging
`ash
# Voir les logs en temps réel
journalctl -u True -f

# Voir les derniers logs
journalctl -u True -n 50

# Voir tous les logs du service
journalctl -u True
`
### Test d'accès Web

`ash
# Vérifier la connectivité HTTP
curl -v http://localhost:

# Ou accédez via votre navigateur
# http://votre-serveur:
`
## Configuration du Firewall

### Avec UFW (Debian/Ubuntu)
`ash
# Autoriser les ports
sudo ufw allow 9090/tcp
# Vérifier les règles
sudo ufw status numbered
`

### Avec Firewall-cmd (RedHat/Fedora)
`ash
# Autoriser les ports de manière permanente
sudo firewall-cmd --permanent --add-port=9090/tcp
# Recharger le firewall
sudo firewall-cmd --reload
`

## Dépannage

### Problèmes Courants

#### Le service ne démarre pas
`ash
# Vérifier les erreurs
sudo journalctl -u True -n 50

# Vérifier la syntaxe de configuration
sudo True --version

# Redémarrer le service
sudo systemctl restart True

# Réappliquer les permissions
sudo chown -R $(whoami):$(whoami) /var/lib/prometheus/
`

#### Port déjà utilisé
`ash
# Trouver quel processus utilise le port
sudo ss -tlnp | grep :True

# Ou
sudo lsof -i :True

# Arrêter le processus conflictuel
sudo kill -9 PID

# Redémarrer le service
sudo systemctl restart True
`

#### Permissions insuffisantes
`ash
# Ajouter l'utilisateur au groupe nécessaire
sudo usermod -aG True $USER

# Appliquer les permissions
sudo chown -R True:True /var/lib/prometheus/

# Se reconnecter pour appliquer les changements de groupe
exit
`

#### Firewall bloque l'accès
`ash
# Vérifier les règles firewall
sudo ufw status numbered

# Ajouter le port si nécessaire
sudo ufw allow True

# Rechec de la connectivité
curl -v http://localhost:True
`

### Vérification du Log Principal
`ash
# Pour les erreurs système
tail -f /var/log/syslog  # Debian/Ubuntu
tail -f /var/log/messages  # RedHat/Fedora

# Pour les erreurs d'application
tail -f /var/log/prometheus/*.log
`

### Réinitialisation Complète

Si vous devez réinitialiser l'installation :
`ash
# 1. Arrêter le service
sudo systemctl stop True

# 2. Désactiver le service
sudo systemctl disable True

# 3. Supprimez l'application (adapter selon les besoins)
sudo rm -rf /opt/prometheus
sudo rm -rf /var/lib/prometheus
sudo rm -rf /etc/prometheus

# 4. Supprimez le service systemd
sudo rm /etc/systemd/system/True.service
sudo systemctl daemon-reload

# 5. Réexécutez le script d'installation
bash install_prometheus.sh
`

## Documentation Officielle

### Ressources Principales
- [Site Officiel](https://example.com)
- [Documentation](https://docs.example.com)
- [GitHub Repository](https://github.com)

### Guides Connexes
- Configuration SSL/TLS
- Haute disponibilité
- Optimisation des performances
- Intégration avec Kubernetes

### Communauté
- Forums de support
- Discord/Slack
- Stack Overflow (tag: prometheus)

## Notes Supplémentaires

### Considérations de Sécurité
1. Utilisez toujours HTTPS en production
2. Configurez les pare-feu correctement
3. Utilisez les mots de passe forts
4. Mettez à jour régulièrement
5. Faites des sauvegardes régulières
6. Limitez l'accès administrateur
7. Utilisez des certificats SSL valides

### Optimisation des Performances
1. Configurez les limites de ressources
2. Ajustez les paramètres de cache
3. Utilisez un load balancer en production
4. Surveillez les métriques
5. Optimisez la base de données

### Sauvegarde et Récupération
`ash
# Créer une sauvegarde complète
sudo tar -czf backup-prometheus-$(date +%Y%m%d).tar.gz /var/lib/prometheus/

# Restaurer une sauvegarde
sudo tar -xzf backup-prometheus-20240101.tar.gz -C /
`

### Mise à Jour
`ash
# Vérifier les mises à jour disponibles
apt list --upgradable  # Debian/Ubuntu
dnf check-update  # RedHat/Fedora

# Mettre à jour
sudo apt upgrade prometheus  # Debian/Ubuntu
sudo dnf upgrade prometheus  # RedHat/Fedora

# Redémarrer le service
sudo systemctl restart True
`

### Restauration de la Configuration par Défaut
`ash
# Sauvegarder la configuration actuelle
sudo cp /etc/prometheus/config /etc/prometheus/config.bak

# Réinstaller depuis les sources
sudo apt install --reinstall prometheus  # Debian/Ubuntu

# Ou, restaurer depuis le paquet
sudo apt-file extract prometheus /etc/
`

### Intégration avec Autres Services
- Reverse Proxy (Nginx, Apache, HAProxy)
- Load Balancer
- Monitoring (Prometheus, Grafana)
- Centralisation des logs (ELK Stack, Loki)
- Orchestration (Docker, Kubernetes)

### Contacts et Support
Pour toute question ou problème :
- Consultez la documentation officielle
- Vérifiez les logs d'erreur
- Contactez le support communautaire
- Ouvrez une issue sur GitHub

---

**Dernière mise à jour** : 03/05/2026

**Version du script d'installation** : 1.0

**Testé sur** : 

**Statut** : Production Ready ✅
