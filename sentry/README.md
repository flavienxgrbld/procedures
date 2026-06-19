# Installation sentry

## Description
Sentry - Monitoring d'erreurs et performance

## Prérequis
- Ubuntu/Debian Linux (ou autre distribution supportée)
- Accès root ou sudo
- Connexion Internet
- Serveur de base de données ou support local selon le service
- Certificat SSL ou accès Internet pour HTTPS

## Installation

Exécutez le script d’installation :

`ash
bash install_sentry.sh
`

### Étapes détaillées
### Installation de Sentry

Le script `install_sentry.sh` installe les dépendances nécessaires et déploie Sentry.
- Mise à jour du système et installation des paquets requis.
- Activation et démarrage des services systemd pour le démarrage automatique.
- Création et configuration d’une base de données si nécessaire.
- Téléchargement des fichiers de l’application depuis le site officiel ou le dépôt.
- Création d’un utilisateur système dédié si nécessaire.
- Ajustement manuel des paramètres de configuration après installation.

## Configuration
Consultez la documentation du service pour adapter les paramètres après installation.

## Vérification
- Vérifiez que le service est actif : `systemctl status [service]` ou l’état du conteneur Docker.
- Accédez à l’URL si applicable.

## Documentation
- [Site officiel](https://sentry.io)
- [Documentation](https://docs.sentry.io/)

## Notes
- Configurez un certificat SSL valide pour l’accès HTTPS.
- Adaptez la configuration à votre environnement avant la mise en production.
- Vérifiez les permissions et l’accès aux fichiers de configuration.
- Mettez à jour régulièrement le service et les dépendances.