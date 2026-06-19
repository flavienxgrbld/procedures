# Installation Jitsi Meet

## Description
Jitsi Meet - Plateforme de visioconférence open source.

## Prérequis
- Ubuntu/Debian Linux.
- Accès root ou sudo.
- Connexion Internet.
- Un nom de domaine pointant vers le serveur.
- Ports 80/tcp, 443/tcp et 10000-20000/udp ouverts.

## Installation

### 1. Mettre à jour le système

`sudo apt update && sudo apt upgrade -y`

### 2. Installer les dépendances

`sudo apt install -y curl gnupg2 apt-transport-https ca-certificates nginx-full`

### 3. Ajouter le dépôt Jitsi

`curl https://download.jitsi.org/jitsi-key.gpg.key | sudo apt-key add -`

`echo "deb https://download.jitsi.org stable/" | sudo tee /etc/apt/sources.list.d/jitsi-stable.list`

`sudo apt update`

### 4. Installer Jitsi Meet

`sudo apt install -y jitsi-meet`

Pendant l’installation, indiquez le nom de domaine principal du service lorsque le prompt le demande.

### 5. Ouvrir les ports

Si vous utilisez UFW :

`sudo ufw allow 80/tcp`

`sudo ufw allow 443/tcp`

`sudo ufw allow 10000:20000/udp`

`sudo ufw reload`

### 6. Installer TLS/SSL

Recommandé : créer un certificat Let's Encrypt :

`sudo /usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh`

Sinon, installez un certificat manuellement dans `/etc/jitsi/meet/`.

## Étapes détaillées
### Configuration manuelle de Jitsi Meet

1. Vérifiez le fichier de configuration principal : `/etc/jitsi/meet/<votre-domaine>-config.js`.
2. Vérifiez la configuration `prosody` dans `/etc/prosody/conf.d/<votre-domaine>.cfg.lua`.
3. Vérifiez la configuration de Jicofo dans `/etc/jitsi/jicofo/config.groovy`.
4. Vérifiez la configuration de Jitsi Videobridge dans `/etc/jitsi/videobridge/sip-communicator.properties`.
5. Si vous utilisez un proxy, configurez le reverse proxy correctement pour `https://<votre-domaine>`.

## Configuration
- Adaptez le domaine dans les fichiers de configuration de Jitsi.
- Vérifiez la présence des certificats TLS dans `/etc/jitsi/meet/`.
- Redémarrez les services après chaque modification :

`sudo systemctl restart prosody`

`sudo systemctl restart jicofo`

`sudo systemctl restart jitsi-videobridge2`

## Vérification
- `sudo systemctl status prosody`
- `sudo systemctl status jicofo`
- `sudo systemctl status jitsi-videobridge2`
- Vérifiez l’accès via `https://<votre-domaine>`.
- Contrôlez les logs :
  - `/var/log/prosody/prosody.log`
  - `/var/log/jitsi/jicofo.log`
  - `/var/log/jitsi/jvb.log`

## Documentation
- [Site officiel](https://jitsi.org/jitsi-meet/)
- [Documentation](https://jitsi.org/qi/)

## Notes
- Utilisez un certificat SSL valide pour un bon fonctionnement des appels.
- Vérifiez les règles de pare-feu et de NAT pour les flux UDP.
- En production, surveillez l’utilisation CPU et RAM selon la charge.
- Pour des installations avancées, consultez la documentation de Jitsi Meet et des composants Prosody, Jicofo et JVB.