# Installation de Bacula

## Description
Bacula est un système de sauvegarde d'entreprise permettant de gérer la sauvegarde, la restauration et la vérification des données sur un réseau.

## Prérequis
- Système d'exploitation : Ubuntu/Debian Linux (ou autre distribution compatible)
- Accès : root ou sudo
- Connexion Internet

## Installation

### Méthode automatique (recommandée)

```bash
bash install_bacula.sh
```

### Installation manuelle (étapes détaillées)

#### 1. Mise à jour du système
```bash
sudo apt update && sudo apt upgrade -y
```

#### 2. Installation de Bacula
```bash
sudo apt install bacula -y
```

#### 3. Installation des composants principaux (optionnel selon besoin)
```bash
sudo apt install bacula-director bacula-console bacula-client bacula-storage -y
```

#### 4. Configuration de la base de données (MySQL/MariaDB)
```bash
sudo apt install mysql-server -y
sudo mysql_secure_installation
```

Configurer la base lors de l'installation ou manuellement selon votre architecture.

#### 5. Activation et démarrage des services
```bash
sudo systemctl enable bacula-director
sudo systemctl enable bacula-sd
sudo systemctl enable bacula-fd

sudo systemctl start bacula-director
sudo systemctl start bacula-sd
sudo systemctl start bacula-fd
```

## Configuration

### Fichiers principaux
- `/etc/bacula/bacula-dir.conf` — configuration du Director
- `/etc/bacula/bacula-sd.conf` — Storage Daemon
- `/etc/bacula/bacula-fd.conf` — File Daemon

### Configuration de base
- Définir les clients à sauvegarder
- Configurer les jobs de sauvegarde
- Définir les volumes et pools
- Configurer les mots de passe entre les composants

Redémarrer les services après modification :
```bash
sudo systemctl restart bacula-director
sudo systemctl restart bacula-sd
sudo systemctl restart bacula-fd
```

## Vérification

```bash
# Vérifier les services
sudo systemctl status bacula-director
sudo systemctl status bacula-sd
sudo systemctl status bacula-fd

# Accéder à la console Bacula
sudo bconsole
```

## Dépannage

```bash
# Logs Director
sudo tail -f /var/log/bacula/bacula.log

# Vérifier la configuration
sudo bacula-dir -t -c /etc/bacula/bacula-dir.conf
```

## Documentation
- Site officiel : https://www.bacula.org/
- Documentation : https://www.bacula.org/documentation/

## Notes
- Bacula nécessite une configuration précise pour fonctionner correctement
- Pensez à tester régulièrement vos restaurations
- Sécurisez les accès entre les composants