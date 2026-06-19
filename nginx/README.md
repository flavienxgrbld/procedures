# Installation nginx

## Description
Nginx - Serveur web haute performance

## Prérequis
- Ubuntu/Debian Linux (ou autre distribution supportée)
- Accès root ou sudo
- Connexion Internet
- Certificat SSL ou accès Internet pour HTTPS

## Installation

Exécutez le script d’installation :

`ash
bash install_nginx.sh
`

### Étapes détaillées
### Installation de Nginx

Le script `install_nginx.sh` installe les dépendances nécessaires et déploie Nginx.
- Mise à jour du système et installation des paquets requis.
- Activation et démarrage des services systemd pour le démarrage automatique.
- Ouverture automatique des ports requis dans UFW si disponible.
- Téléchargement des fichiers de l’application depuis le site officiel ou le dépôt.
- Vérification des ports exposés : 80, 443.
- Ajustement manuel des paramètres de configuration après installation.

## Configuration
Consultez la documentation du service pour adapter les paramètres après installation.

## Vérification
- Vérifiez que le service est actif : `systemctl status [service]` ou l’état du conteneur Docker.
- Accédez à l’URL si applicable.

## Documentation
- [Site officiel](https://nginx.org)
- [Documentation](https://nginx.org/en/docs/)

## Notes
- Configurez un certificat SSL valide pour l’accès HTTPS.
- Adaptez la configuration à votre environnement avant la mise en production.
- Vérifiez les permissions et l’accès aux fichiers de configuration.
- Mettez à jour régulièrement le service et les dépendances.