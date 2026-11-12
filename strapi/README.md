# Strapi — procédure d'installation

## Description

Strapi est un CMS « headless » libre écrit en Node.js : on définit ses types de contenus dans une interface d'administration, et Strapi génère automatiquement une API REST et GraphQL consommée par un site, une application mobile ou tout autre client. Cette procédure crée un projet Strapi 5 avec PostgreSQL et le fait tourner en production avec systemd.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu |
| **Méthode** | `npx create-strapi@latest` + Node.js LTS + PostgreSQL |
| **Dossier** | `/opt/strapi/mon-cms` |
| **Ports** | 1337/tcp |
| **Script** | `install_strapi.sh` |

## Prérequis

- Node.js 20 ou 22 (versions LTS prises en charge).
- PostgreSQL (procédure `postgresql`), ou SQLite pour un essai.
- 2 Go de RAM (la construction de l'interface d'administration est gourmande).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/strapi
sudo bash install_strapi.sh
```

Le script installe Node.js 22 LTS et PostgreSQL, crée la base `strapi` (mot de passe aléatoire), l'utilisateur système `strapi`, puis le projet **sans question** (`create-strapi --non-interactive`, JavaScript, PostgreSQL), construit l'interface d'administration en mode production et crée le service de l'étape 5. Il reste à créer le premier administrateur (étape 6). Variable facultative : `STRAPI_PROJECT`.

## Installation manuelle

### 1. Installer Node.js LTS

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash -
sudo apt install -y nodejs
node -v
```

### 2. Créer la base PostgreSQL

```bash
sudo apt install -y postgresql
sudo -u postgres psql -c "CREATE USER strapi WITH PASSWORD 'MotDePasseBase';"
sudo -u postgres psql -c "CREATE DATABASE strapi OWNER strapi;"
```

### 3. Créer le projet

```bash
sudo useradd -r -m -d /opt/strapi -s /bin/bash strapi
sudo -iu strapi
npx create-strapi@latest mon-cms
```

Répondre aux questions : ignorer la connexion à Strapi Cloud (*Skip*), choisir **TypeScript ou JavaScript**, puis **PostgreSQL** avec les informations de l'étape 2.

### 4. Construire l'interface d'administration

```bash
cd ~/mon-cms
NODE_ENV=production npm run build
exit
```

### 5. Créer le service systemd

`/etc/systemd/system/strapi.service` :

```ini
[Unit]
Description=Strapi
After=network.target postgresql.service

[Service]
User=strapi
WorkingDirectory=/opt/strapi/mon-cms
Environment=NODE_ENV=production
ExecStart=/usr/bin/npm run start
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now strapi
sudo ufw allow 1337/tcp
```

### 6. Créer le compte administrateur

Ouvrir `http://<adresse-du-serveur>:1337/admin` et créer le premier administrateur.

En production, les types de contenus se créent en développement (`npm run develop` sur un poste), puis se déploient sur le serveur : le *Content-Type Builder* est désactivé en mode production.

## Vérification

```bash
systemctl status strapi
curl -I http://localhost:1337/admin
```

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `mon-cms/.env` | Secrets (clés d'application, JWT) et connexion à la base |
| `mon-cms/config/` | Configuration (base, serveur, extensions) |
| `mon-cms/src/api/` | Types de contenus et API générées |

## Points d'attention

- En production, le *Content-Type Builder* est désactivé : les types de contenus se créent en développement (`npm run develop` sur un poste), puis se déploient sur le serveur.
- Créer le premier administrateur dès le démarrage : la page `/admin` le propose à tout visiteur tant qu'il n'existe pas.
- Pour un accès depuis Internet, publier Strapi derrière Nginx en HTTPS.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Installer Strapi (CLI)](https://docs.strapi.io/cms/installation/cli)
- [Déployer Strapi](https://docs.strapi.io/cms/deployment)
