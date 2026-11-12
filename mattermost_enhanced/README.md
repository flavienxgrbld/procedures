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

Le script installe PostgreSQL et crée la base (mot de passe aléatoire), télécharge la dernière version publiée (ou `MM_VERSION`), règle `config.json` (base PostgreSQL et `SiteURL`), crée l'utilisateur `mattermost` et le service systemd de l'étape 5. Variable facultative : `MM_SITE_URL` (ex. `https://chat.exemple.fr` derrière un proxy).

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

Prendre la dernière version sur la page de téléchargement (12.1.0 au 12/11/2026) :

```bash
cd /tmp
wget https://releases.mattermost.com/12.1.0/mattermost-12.1.0-linux-amd64.tar.gz
sudo tar -xzf mattermost-12.1.0-linux-amd64.tar.gz -C /opt
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

- Le premier compte créé devient administrateur système : le créer dès l'installation.
- Pour la production, publier Mattermost derrière Nginx en HTTPS, avec la prise en charge des WebSockets (procédures `nginx` et `certbot`).
- Les versions ESR (Extended Support Release) sont maintenues plus longtemps : les préférer pour un serveur que l'on met peu à jour.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Déployer Mattermost sur Linux](https://docs.mattermost.com/deployment-guide/server/linux/deploy-ubuntu.html)
- [Téléchargements](https://mattermost.com/download/)
