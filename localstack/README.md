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
sudo LOCALSTACK_AUTH_TOKEN=ls-XXXXXXXXXXXX bash install_localstack.sh
```

Le script installe Docker s'il est absent, enregistre le jeton dans `/opt/localstack/.env` (lisible par root seul), écrit le `compose.yaml` de l'étape 2 (port publié sur `127.0.0.1` seulement) et démarre le conteneur, puis installe le client AWS. La configuration du client (étape 3) se fait ensuite sans `sudo`, avec son propre compte.

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

- Le dépôt open source de LocalStack est archivé : l'image actuelle demande un compte (gratuit pour un usage personnel) et son jeton.
- LocalStack n'authentifie pas les requêtes : garder la publication sur `127.0.0.1`. Pour l'utiliser depuis un autre poste, passer par un tunnel SSH (`ssh -L 4566:127.0.0.1:4566 serveur`).
- Le montage de `/var/run/docker.sock` donne au conteneur le contrôle de Docker sur l'hôte : réservé à une machine de développement.
- Sur Debian 13 et Ubuntu 24.04, le paquet `awscli` peut manquer : installer AWS CLI v2 avec l'installateur officiel d'Amazon.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Documentation LocalStack — installation](https://docs.localstack.cloud/getting-started/installation/)
- [Dépôt LocalStack (archivé)](https://github.com/localstack/localstack)
