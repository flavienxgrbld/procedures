# Installation hashicorp_consul

## Description
Hashicorp Consul - Service mesh et service discovery

## Prérequis
- Ubuntu/Debian Linux (ou autre distribution supportée)
- Accès root ou sudo
- Connexion Internet
- Certificat SSL ou accès Internet pour HTTPS

## Installation

Exécutez le script d’installation :

`ash
bash install_hashicorp_consul.sh
`

### Étapes détaillées
### Installation de Hashicorp Consul

Le script `install_hashicorp_consul.sh` installe les dépendances nécessaires et déploie Hashicorp Consul.
- Mise à jour du système et installation des paquets requis.
- Activation et démarrage des services systemd pour le démarrage automatique.
- Téléchargement des fichiers de l’application depuis le site officiel ou le dépôt.
- Création d’un utilisateur système dédié si nécessaire.
- Création éventuelle des répertoires de données et de configuration.
- Ajustement manuel des paramètres de configuration après installation.

## Configuration
Consultez la documentation du service pour adapter les paramètres après installation.

## Vérification
- Vérifiez que le service est actif : `systemctl status [service]` ou l’état du conteneur Docker.
- Accédez à l’URL si applicable.

## Documentation
- [Site officiel](https://www.consul.io)
- [Documentation](https://www.consul.io/docs/)

## Notes
- Configurez un certificat SSL valide pour l’accès HTTPS.
- Adaptez la configuration à votre environnement avant la mise en production.
- Vérifiez les permissions et l’accès aux fichiers de configuration.
- Mettez à jour régulièrement le service et les dépendances.