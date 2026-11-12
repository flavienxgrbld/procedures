# Woodpecker CI — procédure d'installation

## Description

Woodpecker CI est un moteur d'intégration continue libre et léger : il exécute des pipelines décrits dans un fichier `.woodpecker.yaml` du dépôt, chaque étape tournant dans un conteneur. Il se connecte à une forge Git (Gitea, Forgejo, GitHub, GitLab…). Cette procédure installe le serveur et un agent avec Docker Compose, reliés à une instance Gitea.

| | |
|---|---|
| **Systèmes** | Toute distribution avec Docker |
| **Méthode** | Images officielles `woodpeckerci/woodpecker-server` et `woodpecker-agent` (v3) |
| **Dossier** | `/opt/woodpecker` |
| **Ports** | 8000/tcp (interface web), 9000/tcp (communication agents) |
| **Script** | `install_woodpecker_ci.sh` |

## Prérequis

- Docker et Docker Compose (procédure `docker`).
- Une forge Git : ici Gitea (procédure `gitea_self_hosted`), accessible depuis le serveur Woodpecker.

## Installation automatique

Créer d'abord l'application OAuth2 dans Gitea (étape 1), puis :

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/woodpecker_ci
sudo WP_HOST=http://192.168.1.90:8000 WP_GITEA_URL=http://192.168.1.85:3000 \
     WP_GITEA_CLIENT=<identifiant> WP_GITEA_SECRET=<secret> WP_ADMIN=flavien bash install_woodpecker_ci.sh
```

Le script installe Docker s'il est absent, génère le secret partagé entre serveur et agent (étape 2), écrit le `compose.yaml` de l'étape 3 (serveur + agent, inscriptions fermées) avec les valeurs dans `/opt/woodpecker/.env`, puis démarre les conteneurs.

## Installation manuelle

### 1. Créer l'application OAuth dans Gitea

Dans Gitea : *Paramètres → Applications → Créer une nouvelle application OAuth2* :

- nom : `Woodpecker` ;
- URL de redirection : `http://<adresse-woodpecker>:8000/authorize`.

Noter l'**identifiant client** et le **secret client**.

### 2. Générer le secret partagé avec les agents

```bash
openssl rand -hex 32
```

### 3. Décrire les services

```bash
sudo mkdir -p /opt/woodpecker
cd /opt/woodpecker
```

`/opt/woodpecker/compose.yaml` :

```yaml
services:
  woodpecker-server:
    image: woodpeckerci/woodpecker-server:v3
    restart: unless-stopped
    ports:
      - "8000:8000"
    volumes:
      - woodpecker-server-data:/var/lib/woodpecker/
    environment:
      WOODPECKER_HOST: http://<adresse-woodpecker>:8000
      WOODPECKER_OPEN: "false"
      WOODPECKER_ADMIN: flavien
      WOODPECKER_GITEA: "true"
      WOODPECKER_GITEA_URL: http://<adresse-gitea>:3000
      WOODPECKER_GITEA_CLIENT: <identifiant client>
      WOODPECKER_GITEA_SECRET: <secret client>
      WOODPECKER_AGENT_SECRET: <secret de l'étape 2>

  woodpecker-agent:
    image: woodpeckerci/woodpecker-agent:v3
    restart: unless-stopped
    command: agent
    depends_on: [woodpecker-server]
    volumes:
      - woodpecker-agent-config:/etc/woodpecker
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      WOODPECKER_SERVER: woodpecker-server:9000
      WOODPECKER_AGENT_SECRET: <secret de l'étape 2>

volumes:
  woodpecker-server-data:
  woodpecker-agent-config:
```

`WOODPECKER_ADMIN` désigne le compte Gitea qui administre Woodpecker.

### 4. Démarrer

```bash
sudo docker compose up -d
sudo ufw allow 8000/tcp
```

### 5. Activer un dépôt et lancer un pipeline

1. Ouvrir `http://<adresse-woodpecker>:8000`, se connecter avec Gitea et autoriser l'application.
2. **Ajouter un dépôt** et l'activer.
3. Ajouter à la racine du dépôt un fichier `.woodpecker.yaml` :

```yaml
steps:
  - name: test
    image: alpine
    commands:
      - echo "Woodpecker fonctionne"
      - uname -a
```

Chaque `git push` déclenche le pipeline, visible dans Woodpecker.

## Vérification

```bash
sudo docker compose ps
sudo docker compose logs woodpecker-agent | tail
```

L'agent apparaît dans *Paramètres → Agents* de Woodpecker.

## Points d'attention

- `WOODPECKER_OPEN=false` : seuls les comptes déjà connus peuvent se connecter ; ne l'ouvrir qu'en cas de besoin explicite.
- L'agent a accès au socket Docker, donc aux droits root sur l'hôte : n'activer que des dépôts de confiance.
- L'URL de redirection déclarée dans Gitea doit être exactement `<WP_HOST>/authorize`.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Installer Woodpecker avec Docker Compose](https://woodpecker-ci.org/docs/administration/installation/docker-compose)
- [Configurer la forge Gitea](https://woodpecker-ci.org/docs/administration/configuration/forges/gitea)
