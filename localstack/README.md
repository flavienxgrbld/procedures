# LocalStack — procédure d'installation

## Description

LocalStack émule les services d'Amazon Web Services (S3, Lambda, DynamoDB, SQS…) sur une machine locale, dans un conteneur Docker. On peut ainsi développer et tester des applications AWS ou des scripts Terraform sans compte AWS ni frais.

| | |
|---|---|
| **Systèmes** | Toute distribution avec Docker |
| **Méthode** | Image Docker `localstack/localstack` |
| **Ports** | 4566/tcp (point d'accès unique pour tous les services) |
| **Script** | `install_localstack.sh` |

## Prérequis

- Docker installé (voir la procédure `docker`).
- Un compte LocalStack et son **jeton d'authentification** (*Auth Token*). L'offre *Hobby* est gratuite pour un usage non commercial.
- Le client AWS (`awscli`) pour envoyer des commandes.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/localstack
sudo bash install_localstack.sh
```

Lire les points d'attention : sur les distributions récentes, le script s'arrête avant de lancer le conteneur.

## Installation manuelle

### 1. Récupérer le jeton d'authentification

Créer un compte sur le site de LocalStack, puis copier le jeton affiché dans *Workspace → Auth Token*.

### 2. Démarrer LocalStack

`/opt/localstack/compose.yaml` :

```yaml
services:
  localstack:
    image: localstack/localstack:latest
    container_name: localstack
    restart: unless-stopped
    ports:
      - "127.0.0.1:4566:4566"
    environment:
      LOCALSTACK_AUTH_TOKEN: "ls-XXXXXXXXXXXX"
    volumes:
      - localstack_data:/var/lib/localstack
      - /var/run/docker.sock:/var/run/docker.sock

volumes:
  localstack_data:
```

```bash
cd /opt/localstack
sudo docker compose up -d
```

L'accès au socket Docker est nécessaire pour exécuter des fonctions Lambda. Le port n'est publié que sur `127.0.0.1` : LocalStack n'a pas d'authentification par requête.

### 3. Installer et configurer le client AWS

```bash
sudo apt install -y awscli
aws configure set aws_access_key_id test
aws configure set aws_secret_access_key test
aws configure set region eu-west-3
```

### 4. Utiliser les services

```bash
aws --endpoint-url=http://localhost:4566 s3 mb s3://mon-bucket
aws --endpoint-url=http://localhost:4566 s3 cp fichier.txt s3://mon-bucket/
aws --endpoint-url=http://localhost:4566 s3 ls s3://mon-bucket
```

## Vérification

```bash
curl -s http://localhost:4566/_localstack/health
```

La réponse liste les services disponibles et leur état.

## Dépannage

- Le conteneur s'arrête au démarrage : jeton absent ou invalide. Vérifier avec `sudo docker compose logs localstack`.
- Mise à jour : `sudo docker compose pull && sudo docker compose up -d`.

## Points d'attention

- Le script installe la CLI LocalStack avec `pip3 install localstack` dans le Python du système. Sur Debian 12 et Ubuntu 23.04 et plus récents, cette commande est refusée (« externally-managed-environment ») : le script s'arrête avant de démarrer le conteneur. La documentation demande aussi de ne jamais l'installer en root.
- Le script lance le conteneur sans jeton d'authentification. Le dépôt open source de LocalStack est archivé : l'image actuelle demande un compte, même gratuit.
- Il publie le port 4566 sur toutes les interfaces et l'ouvre dans le pare-feu : n'importe quelle machine du réseau peut alors utiliser l'émulateur. Le port 4571 qu'il publie appartient à d'anciennes versions.

## Sources

- [Documentation LocalStack — installation](https://docs.localstack.cloud/getting-started/installation/)
- [Dépôt LocalStack (archivé)](https://github.com/localstack/localstack)
