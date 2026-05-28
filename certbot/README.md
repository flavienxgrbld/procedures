# Installation de Certbot

## Description
Certbot est un outil permettant de générer et renouveler automatiquement des certificats SSL/TLS gratuits via Let's Encrypt afin de sécuriser les services web en HTTPS.

## Prérequis
- Système d'exploitation : Ubuntu/Debian Linux (ou autre distribution compatible)
- Accès : root ou sudo
- Connexion Internet
- Nom de domaine pointant vers votre serveur
- Serveur web (Apache ou Nginx recommandé)

## Installation

### Méthode automatique (recommandée)

```bash
bash install_certbot.sh
```

### Installation manuelle (étapes détaillées)

#### 1. Mise à jour du système
```bash
sudo apt update && sudo apt upgrade -y
```

#### 2. Installation de Certbot

##### Avec Apache
```bash
sudo apt install certbot python3-certbot-apache -y
```

##### Avec Nginx
```bash
sudo apt install certbot python3-certbot-nginx -y
```

##### Méthode universelle (snap recommandé)
```bash
sudo apt install snapd -y
sudo snap install core
sudo snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
```

#### 3. Génération d'un certificat SSL

##### Avec Apache
```bash
sudo certbot --apache
```

##### Avec Nginx
```bash
sudo certbot --nginx
```

##### Mode standalone
```bash
sudo certbot certonly --standalone -d votre-domaine.com
```

Suivez les instructions pour :
- Valider votre domaine
- Configurer HTTPS automatiquement
- Activer la redirection HTTP → HTTPS

#### 4. Renouvellement automatique
```bash
sudo certbot renew --dry-run
```

Un cron ou timer systemd est généralement installé automatiquement.

## Configuration

### Emplacement des certificats
- `/etc/letsencrypt/live/` — certificats actifs
- `/etc/letsencrypt/archive/` — historique
- `/etc/letsencrypt/renewal/` — configuration de renouvellement

### Configuration Apache/Nginx
Certbot peut modifier automatiquement la configuration pour activer HTTPS.

Exemple Apache :
```
<VirtualHost *:443>
    ServerName votre-domaine.com
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/votre-domaine.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/votre-domaine.com/privkey.pem
</VirtualHost>
```

## Vérification

```bash
# Vérifier Certbot
certbot --version

# Tester le renouvellement
sudo certbot renew --dry-run

# Tester HTTPS
curl -I https://votre-domaine.com
```

## Dépannage

```bash
# Logs Certbot
sudo tail -f /var/log/letsencrypt/letsencrypt.log

# Vérifier ports
sudo ss -tlnp | grep :80
sudo ss -tlnp | grep :443

# Vérifier configuration web
sudo apache2ctl configtest
sudo nginx -t
```

## Documentation
- Site officiel : https://certbot.eff.org/
- Documentation : https://certbot.eff.org/docs/
- Let's Encrypt : https://letsencrypt.org/

## Notes
- Assurez-vous que le port 80 est accessible pour la validation
- Les certificats expirent tous les 90 jours (renouvellement automatique recommandé)
- Utilisez HTTPS pour sécuriser toutes vos applications web