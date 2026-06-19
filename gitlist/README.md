# Installation gitlist

## Description
Gitlist - Navigateur Git web

## Prérequis
- Ubuntu/Debian Linux (ou autre distribution supportée)
- Accès root ou sudo
- Connexion Internet
- Certificat SSL ou accès Internet pour HTTPS

## Installation

Exécutez le script d’installation :

`ash
bash install_gitlist.sh
`

### Étapes détaillées
### Installation de Gitlist

Le script `install_gitlist.sh` installe les dépendances nécessaires et déploie Gitlist.
- Mise à jour du système et installation des paquets requis.
- Activation et démarrage des services systemd pour le démarrage automatique.
- Téléchargement des fichiers de l’application depuis le site officiel ou le dépôt.
- Ajustement manuel des paramètres de configuration après installation.

## Configuration
Consultez la documentation du service pour adapter les paramètres après installation.

## Vérification
- Vérifiez que le service est actif : `systemctl status [service]` ou l’état du conteneur Docker.
- Accédez à l’URL si applicable.

## Documentation
- [Site officiel](https://gitlist.org)
- [Documentation](https://gitlist.org/docs)

## Notes
- Configurez un certificat SSL valide pour l’accès HTTPS.
- Adaptez la configuration à votre environnement avant la mise en production.
- Vérifiez les permissions et l’accès aux fichiers de configuration.
- Mettez à jour régulièrement le service et les dépendances.