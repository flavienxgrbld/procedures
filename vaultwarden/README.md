# Vaultwarden — procédure d'installation

## Description

Vaultwarden est une implémentation légère et libre du serveur Bitwarden : il permet d'héberger soi-même son gestionnaire de mots de passe, compatible avec les applications et extensions officielles Bitwarden (ordinateur, navigateur, téléphone). Cette procédure l'installe avec Docker, derrière Caddy, qui fournit le HTTPS automatique indispensable.

| | |
|---|---|
| **Systèmes** | Toute distribution avec Docker |
| **Méthode** | Image `vaultwarden/server` + proxy Caddy (HTTPS) |
| **Dossier** | `/opt/vaultwarden` |
| **Ports** | 80/tcp et 443/tcp (Caddy) |
| **Script** | `install_vaultwarden.sh` |

## Prérequis

- Docker et Docker Compose (procédure `docker`).
- Un **nom de domaine** (ici `vault.exemple.fr`) pointant vers le serveur : l'interface web exige HTTPS.

## Installation automatique

Le nom de domaine doit pointer vers le serveur (ports 80 et 443 joignables) :

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/vaultwarden
sudo VW_DOMAIN=vault.exemple.fr bash install_vaultwarden.sh
```

Le script installe Docker s'il est absent, génère le jeton d'administration au format argon2id (étape 2, mot de passe dans `/root/vaultwarden_identifiants.txt`), écrit le `compose.yaml` et le `Caddyfile` de l'étape 3 (HTTPS automatique) et démarre les conteneurs. Il reste à créer les comptes puis à fermer les inscriptions (étape 5).

## Installation manuelle

### 1. Préparer le dossier

```bash
sudo mkdir -p /opt/vaultwarden
cd /opt/vaultwarden
```

### 2. Générer le jeton d'administration

```bash
sudo docker run --rm -it vaultwarden/server /vaultwarden hash
```

Saisir un mot de passe d'administration : la commande renvoie une chaîne `$argon2id$...`.

### 3. Décrire les services

`/opt/vaultwarden/compose.yaml` :

```yaml
services:
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    restart: unless-stopped
    environment:
      DOMAIN: "https://vault.exemple.fr"
      SIGNUPS_ALLOWED: "true"
      ADMIN_TOKEN: '$$argon2id$$...'    # doubler chaque $ dans un fichier Compose
    volumes:
      - ./vw-data:/data

  caddy:
    image: caddy:2
    container_name: caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - ./caddy-data:/data
```

`/opt/vaultwarden/Caddyfile` :

```caddy
vault.exemple.fr {
    reverse_proxy vaultwarden:80
}
```

### 4. Démarrer

```bash
sudo docker compose up -d
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### 5. Créer les comptes, puis fermer les inscriptions

1. Ouvrir `https://vault.exemple.fr` et créer son compte (le mot de passe maître ne peut pas être récupéré en cas d'oubli).
2. Une fois les comptes créés, passer `SIGNUPS_ALLOWED` à `"false"`, puis `sudo docker compose up -d`.
3. L'administration (`https://vault.exemple.fr/admin`, avec le mot de passe de l'étape 2) permet d'inviter des utilisateurs et de configurer le SMTP.

### 6. Utiliser les applications Bitwarden

Dans l'application ou l'extension Bitwarden, choisir **Auto-hébergé** et saisir l'URL `https://vault.exemple.fr`.

## Vérification

```bash
sudo docker compose ps
curl -I https://vault.exemple.fr/alive
```

## Sauvegarde

Sauvegarder régulièrement `/opt/vaultwarden/vw-data` (base `db.sqlite3`, clés `rsa_key*`, pièces jointes), de préférence vers une autre machine.

## Points d'attention

- Fermer les inscriptions (`SIGNUPS_ALLOWED=false`) dès que les comptes de l'équipe sont créés : sinon, tout visiteur peut créer un coffre sur le serveur.
- Le mot de passe maître d'un coffre ne peut pas être récupéré en cas d'oubli.
- Sauvegarder régulièrement `/opt/vaultwarden/vw-data` (base, pièces jointes, clés).
- Relu et mis à jour le 12/11/2026.

## Sources

- [Wiki Vaultwarden](https://github.com/dani-garcia/vaultwarden/wiki)
- [Proxy inverse et HTTPS](https://github.com/dani-garcia/vaultwarden/wiki/Proxy-examples)
