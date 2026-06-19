# Installation moodle

## Description
Moodle - Plateforme d'apprentissage en ligne

## Prérequis
- Ubuntu/Debian Linux (ou autre distribution supportée)
- Accès root ou sudo
- Connexion Internet
- Certificat SSL ou accès Internet pour HTTPS

## Installation

Exécutez le script d’installation :

`ash
bash install_moodle.sh
`

### Étapes détaillées
### Installation de Moodle

Le script `install_moodle.sh` installe les dépendances nécessaires et déploie Moodle.
- Mise à jour du système et installation des paquets requis.
- Téléchargement des fichiers de l’application depuis le site officiel ou le dépôt.
- Création éventuelle des répertoires de données et de configuration.
- Ajustement manuel des paramètres de configuration après installation.

## Configuration
Consultez la documentation du service pour adapter les paramètres après installation.

## Vérification
- Vérifiez que le service est actif : `systemctl status [service]` ou l’état du conteneur Docker.
- Accédez à l’URL si applicable.

## Documentation
- [Site officiel](https://moodle.org)
- [Documentation](https://docs.moodle.org/)

## Notes
- Configurez un certificat SSL valide pour l’accès HTTPS.
- Adaptez la configuration à votre environnement avant la mise en production.
- Vérifiez les permissions et l’accès aux fichiers de configuration.
- Mettez à jour régulièrement le service et les dépendances.