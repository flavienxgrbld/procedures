# Installation portainer

## Description
Portainer - Interface de gestion Docker

## Prérequis
- Ubuntu/Debian Linux (ou autre distribution supportée)
- Accès root ou sudo
- Connexion Internet
- Docker installé si le script utilise des conteneurs
- Certificat SSL ou accès Internet pour HTTPS

## Installation

Exécutez le script d’installation :

`ash
bash install_portainer.sh
`

### Étapes détaillées
### Installation de Portainer

Le script `install_portainer.sh` installe les dépendances nécessaires et déploie Portainer.
- Mise à jour du système et installation des paquets requis.
- Exécution de conteneurs Docker via `docker run`.
- Téléchargement des fichiers de l’application depuis le site officiel ou le dépôt.
- Vérification des ports exposés : 8000, 9443.
- Ajustement manuel des paramètres de configuration après installation.

## Configuration
Consultez la documentation du service pour adapter les paramètres après installation.

## Vérification
- Vérifiez que le service est actif : `systemctl status [service]` ou l’état du conteneur Docker.
- Accédez à l’URL si applicable.

## Documentation
- [Site officiel](https://www.portainer.io)
- [Documentation](https://documentation.portainer.io/)

## Notes
- Configurez un certificat SSL valide pour l’accès HTTPS.
- Adaptez la configuration à votre environnement avant la mise en production.
- Vérifiez les permissions et l’accès aux fichiers de configuration.
- Mettez à jour régulièrement le service et les dépendances.