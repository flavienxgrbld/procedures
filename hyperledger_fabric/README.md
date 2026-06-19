# Installation hyperledger_fabric

## Description
Hyperledger Fabric - Blockchain d'entreprise

## Prérequis
- Ubuntu/Debian Linux (ou autre distribution supportée)
- Accès root ou sudo
- Connexion Internet
- Docker installé si le script utilise des conteneurs
- Certificat SSL ou accès Internet pour HTTPS

## Installation

Exécutez le script d’installation :

`ash
bash install_hyperledger_fabric.sh
`

### Étapes détaillées
### Installation de Hyperledger Fabric

Le script `install_hyperledger_fabric.sh` installe les dépendances nécessaires et déploie Hyperledger Fabric.
- Mise à jour du système et installation des paquets requis.
- Déploiement de conteneurs Docker via `docker-compose` ou `docker run`.
- Activation et démarrage des services systemd pour le démarrage automatique.
- Téléchargement des fichiers de l’application depuis le site officiel ou le dépôt.
- Création éventuelle des répertoires de données et de configuration.
- Ajustement manuel des paramètres de configuration après installation.

## Configuration
Consultez la documentation du service pour adapter les paramètres après installation.

## Vérification
- Vérifiez que le service est actif : `systemctl status [service]` ou l’état du conteneur Docker.
- Accédez à l’URL si applicable.

## Documentation
- [Site officiel](https://www.hyperledger.org/use/fabric)
- [Documentation](https://hyperledger-fabric.readthedocs.io/)

## Notes
- Configurez un certificat SSL valide pour l’accès HTTPS.
- Adaptez la configuration à votre environnement avant la mise en production.
- Vérifiez les permissions et l’accès aux fichiers de configuration.
- Mettez à jour régulièrement le service et les dépendances.