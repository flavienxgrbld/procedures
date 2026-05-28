# Installation de Duplicati

## Description
Duplicati est une solution de sauvegarde open source permettant de réaliser des backups chiffrés, compressés et stockés localement ou dans le cloud.

### Type
Application de sauvegarde

## Prérequis

- **Système d'exploitation** : Ubuntu 20.04 LTS ou plus récent / Debian 11+ / CentOS 8+ / Fedora / openSUSE / Arch Linux
- **Accès** : root ou sudo
- **Ressources** : minimum 2 Go de RAM recommandé
- **Réseau** : connexion Internet stable (pour installation et stockage cloud)
- **Ports** : 8200/tcp (interface web)
- **Dépendances** : curl, wget, git (installés automatiquement si nécessaire)

## Installation

### Méthode automatique (recommandée)

```bash
# 1. Rendez le script exécutable
chmod +x install_duplicati.sh

# 2. Lancez l'installation
bash install_duplicati.sh

# 3. Suivez les instructions affichées
```

### Installation manuelle (étapes détaillées)

#### 1. Mise à jour du système
```bash
sudo apt update && sudo apt upgrade -y
```

#### 2. Installation des dépendances
```bash
sudo apt install wget curl unzip mono-complete -y
```

#### 3. Téléchargement de Duplicati
```bash
wget https://updates.duplicati.com/beta/duplicati-2.0.7.1_beta_2023-05-25.zip
unzip duplicati-*.zip
sudo mv Duplicati /opt/duplicati
```

#### 4. Création du service systemd
```bash
sudo nano /etc/systemd/system/duplicati.service
```

Contenu :
```
[Unit]
Description=Duplicati Backup Service
After=network.target

[Service]
ExecStart=/usr/bin/mono /opt/duplicati/Duplicati.Server.exe
Restart=always
User=root

[Install]
WantedBy=multi-user.target
```

#### 5. Activation du service
```bash
sudo systemctl daemon-reload
sudo systemctl enable duplicati
sudo systemctl start duplicati
```

## Configuration

### Accès interface web
```
http://localhost:8200
```

ou
```
http://IP_DU_SERVEUR:8200
```

### Dossier de configuration
- `/root/.config/Duplicati/`
- `/var/lib/duplicati/`

## Vérification

```bash
# Vérifier le service
systemctl status duplicati

# Vérifier le port
ss -tlnp | grep 8200

# Logs
journalctl -u duplicati -f
```

## Configuration firewall

### UFW
```bash
sudo ufw allow 8200/tcp
```

### firewall-cmd
```bash
sudo firewall-cmd --permanent --add-port=8200/tcp
sudo firewall-cmd --reload
```

## Dépannage

```bash
# Vérifier logs
journalctl -u duplicati -n 50

# Processus utilisant le port
sudo lsof -i :8200

# Redémarrer service
sudo systemctl restart duplicati
```

## Sauvegarde avec Duplicati

Duplicati permet de sauvegarder vers :
- Disque local
- FTP / SFTP
- Google Drive
- Amazon S3
- OneDrive

## Documentation
- Site officiel : https://www.duplicati.com/
- Documentation : https://docs.duplicati.com/

## Notes
- L'interface web fonctionne par défaut sur le port 8200
- Pensez à sécuriser l'accès (reverse proxy + HTTPS recommandé)
- Solution idéale pour backups automatisés et chiffrés