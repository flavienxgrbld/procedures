# Mattermost — procédure d'installation

## Description

Mattermost est une plateforme de messagerie d'équipe auto-hébergée, alternative à Slack : canaux, messages privés, partage de fichiers, appels, intégrations et tableaux de projet. Cette procédure installe le serveur à partir de l'archive officielle, avec PostgreSQL, sous forme de service systemd.

| | |
|---|---|
| **Systèmes** | Ubuntu, Debian (64 bits) |
| **Méthode** | Archive officielle + PostgreSQL |
| **Dossier** | `/opt/mattermost` |
| **Ports** | 8065/tcp (ou 443 derrière un proxy inverse) |
| **Script** | `install_mattermost_enhanced.sh` |

## Prérequis

- 2 Go de RAM au minimum (4 Go conseillés).
- PostgreSQL (installé à l'étape 1).
- Un accès root et une connexion Internet.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/mattermost_enhanced
sudo bash install_mattermost_enhanced.sh
```

Lire les points d'attention : le script ne parvient plus à télécharger Mattermost et ne configure pas la base.

## Installation manuelle

### 1. Installer PostgreSQL et créer la base

```bash
sudo apt update
sudo apt install -y postgresql
sudo -u postgres psql
```

```sql
CREATE DATABASE mattermost;
CREATE USER mmuser WITH PASSWORD 'MotDePasseFort';
ALTER DATABASE mattermost OWNER TO mmuser;
GRANT USAGE, CREATE ON SCHEMA public TO mmuser;
\q
```

### 2. Télécharger Mattermost

Prendre la dernière version sur la page de téléchargement (ici la 11.11.1) :

```bash
cd /tmp
wget https://releases.mattermost.com/11.11.1/mattermost-11.11.1-linux-amd64.tar.gz
sudo tar -xzf mattermost-11.11.1-linux-amd64.tar.gz -C /opt
sudo mkdir -p /opt/mattermost/data
```

### 3. Créer l'utilisateur et les droits

```bash
sudo useradd --system --user-group mattermost
sudo chown -R mattermost:mattermost /opt/mattermost
sudo chmod -R g+w /opt/mattermost
```

### 4. Configurer la base de données

Dans `/opt/mattermost/config/config.json`, section `SqlSettings` :

```json
"DriverName": "postgres",
"DataSource": "postgres://mmuser:MotDePasseFort@localhost/mattermost?sslmode=disable&connect_timeout=10",
```

Et dans `ServiceSettings` :

```json
"SiteURL": "https://chat.exemple.fr",
```

### 5. Créer le service systemd

`/lib/systemd/system/mattermost.service` :

```ini
[Unit]
Description=Mattermost
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=notify
ExecStart=/opt/mattermost/bin/mattermost
TimeoutStartSec=3600
KillMode=mixed
Restart=always
RestartSec=10
WorkingDirectory=/opt/mattermost
User=mattermost
Group=mattermost
LimitNOFILE=49152

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now mattermost
sudo ufw allow 8065/tcp
```

### 6. Première connexion

Ouvrir `http://<adresse-du-serveur>:8065`, créer le compte administrateur (le premier compte créé l'est automatiquement), puis la première équipe.

Pour la production, publier Mattermost derrière Nginx en HTTPS (procédures `nginx` et `certbot`), avec la prise en charge des WebSockets.

## Vérification

```bash
systemctl status mattermost
curl -s http://localhost:8065/api/v4/system/ping
```

`/system/ping` doit répondre `"status":"OK"`.

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/opt/mattermost/config/config.json` | Configuration |
| `/opt/mattermost/data/` | Fichiers envoyés |
| `/opt/mattermost/logs/mattermost.log` | Journal |

## Points d'attention

- Le script télécharge Mattermost 7.8.0 à une adresse qui ne répond plus (erreur 403, vérifié le 13/10/2026) : il s'arrête au téléchargement. Cette version ne reçoit plus de correctifs de sécurité.
- Il crée une base MySQL sans jamais l'indiquer dans `config.json` : Mattermost ne peut pas se connecter à sa base. Les versions récentes de Mattermost fonctionnent avec PostgreSQL.
- Son service n'indique ni `WorkingDirectory` ni de dépendance à la base de données.

## Sources

- [Déployer Mattermost sur Linux](https://docs.mattermost.com/deployment-guide/server/linux/deploy-ubuntu.html)
- [Téléchargements](https://mattermost.com/download/)
