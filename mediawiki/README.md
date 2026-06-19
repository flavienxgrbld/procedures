# Installation mediawiki

## Description
MediaWiki - Moteur wiki utilisé par Wikipedia

## Prérequis
- Ubuntu/Debian Linux (ou autre distribution supportée)
- Accès root ou sudo
- Connexion Internet
- Serveur de base de données ou support local selon le service
- Certificat SSL ou accès Internet pour HTTPS

## Installation

Exécutez le script d’installation :

`ash
bash install_mediawiki.sh
`

### Étapes détaillées
### Installation de Mediawiki

Le script `install_mediawiki.sh` installe les dépendances nécessaires et déploie Mediawiki.
- Mise à jour du système et installation des paquets requis.
- Création et configuration d’une base de données si nécessaire.
- Téléchargement des fichiers de l’application depuis le site officiel ou le dépôt.
- Ajustement manuel des paramètres de configuration après installation.

## Configuration
Consultez la documentation du service pour adapter les paramètres après installation.

## Vérification
- Vérifiez que le service est actif : `systemctl status [service]` ou l’état du conteneur Docker.
- Accédez à l’URL si applicable.

## Documentation
- [Site officiel](https://www.mediawiki.org)
- [Documentation](https://www.mediawiki.org/wiki/Documentation)

## Notes
- Configurez un certificat SSL valide pour l’accès HTTPS.
- Adaptez la configuration à votre environnement avant la mise en production.
- Vérifiez les permissions et l’accès aux fichiers de configuration.
- Mettez à jour régulièrement le service et les dépendances.