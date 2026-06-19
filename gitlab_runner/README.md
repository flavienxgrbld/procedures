# Installation gitlab_runner

## Description
GitLab Runner - Runner CI/CD pour GitLab

## Prérequis
- Ubuntu/Debian Linux (ou autre distribution supportée)
- Accès root ou sudo
- Connexion Internet
- Docker installé si le script utilise des conteneurs
- Certificat SSL ou accès Internet pour HTTPS

## Installation

Exécutez le script d’installation :

`ash
bash install_gitlab_runner.sh
`

### Étapes détaillées
### Installation de Gitlab Runner

Le script `install_gitlab_runner.sh` installe les dépendances nécessaires et déploie Gitlab Runner.
- Mise à jour du système et installation des paquets requis.
- Exécution de conteneurs Docker via `docker run`.
- Activation et démarrage des services systemd pour le démarrage automatique.
- Téléchargement des fichiers de l’application depuis le site officiel ou le dépôt.
- Ajustement manuel des paramètres de configuration après installation.

## Configuration
Consultez la documentation du service pour adapter les paramètres après installation.

## Vérification
- Vérifiez que le service est actif : `systemctl status [service]` ou l’état du conteneur Docker.
- Accédez à l’URL si applicable.

## Documentation
- [Site officiel](https://docs.gitlab.com/runner/)
- [Documentation](https://docs.gitlab.com/runner/)

## Notes
- Configurez un certificat SSL valide pour l’accès HTTPS.
- Adaptez la configuration à votre environnement avant la mise en production.
- Vérifiez les permissions et l’accès aux fichiers de configuration.
- Mettez à jour régulièrement le service et les dépendances.