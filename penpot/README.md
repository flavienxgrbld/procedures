# Installation penpot

## Description
Penpot - Plateforme de design collaborative

## Prérequis
- Ubuntu/Debian Linux (ou autre distribution supportée)
- Accès root ou sudo
- Connexion Internet
- Docker installé si le script utilise des conteneurs
- Certificat SSL ou accès Internet pour HTTPS

## Installation

Exécutez le script d’installation :

`ash
bash install_penpot.sh
`

### Étapes détaillées
### Installation de Penpot

Le script `install_penpot.sh` installe les dépendances nécessaires et déploie Penpot.
- Mise à jour du système et installation des paquets requis.
- Déploiement de conteneurs Docker via `docker-compose` ou `docker run`.
- Ouverture automatique des ports requis dans UFW si disponible.
- Téléchargement des fichiers de l’application depuis le site officiel ou le dépôt.
- Vérification des ports exposés : 80.
- Création éventuelle des répertoires de données et de configuration.
- Ajustement manuel des paramètres de configuration après installation.

## Configuration
Consultez la documentation du service pour adapter les paramètres après installation.

## Vérification
- Vérifiez que le service est actif : `systemctl status [service]` ou l’état du conteneur Docker.
- Accédez à l’URL si applicable.

## Documentation
- [Site officiel](https://penpot.app)
- [Documentation](https://help.penpot.app)

## Notes
- Configurez un certificat SSL valide pour l’accès HTTPS.
- Adaptez la configuration à votre environnement avant la mise en production.
- Vérifiez les permissions et l’accès aux fichiers de configuration.
- Mettez à jour régulièrement le service et les dépendances.