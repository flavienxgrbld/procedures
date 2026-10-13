# Gitea — procédure d'installation

## Description

Gitea est un service Git auto-hébergé léger, comparable à GitHub ou GitLab : dépôts, tickets, demandes de fusion, wiki, gestion des équipes et intégration continue (Gitea Actions). Cette procédure l'installe à partir du binaire officiel, sous forme de service systemd.

| | |
|---|---|
| **Systèmes** | Linux 64 bits avec systemd |
| **Méthode** | Binaire officiel |
| **Ports** | 3000/tcp (web) ; 22/tcp (SSH, via le serveur SSH du système) |
| **Script** | `install_gitea_self_hosted.sh` |

## Prérequis

- Un accès root et une connexion Internet.
- `git` installé sur le serveur.
- Optionnel : une base MariaDB ou PostgreSQL. SQLite convient pour un usage personnel ou un labo.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/gitea_self_hosted
sudo bash install_gitea_self_hosted.sh
```

Le script crée l'utilisateur `git`, installe le binaire Gitea 1.20.0 et démarre le service. L'installation se termine dans le navigateur (étape 5).

## Installation manuelle

### 1. Installer Git et créer l'utilisateur

```bash
sudo apt update
sudo apt install -y git
sudo adduser --system --shell /bin/bash --group --disabled-password --home /home/git git
```

### 2. Créer les dossiers

```bash
sudo mkdir -p /var/lib/gitea/{custom,data,log}
sudo chown -R git:git /var/lib/gitea
sudo chmod -R 750 /var/lib/gitea
sudo mkdir -p /etc/gitea
sudo chown root:git /etc/gitea
sudo chmod 770 /etc/gitea
```

### 3. Installer le binaire

Prendre la dernière version sur la page des versions (ici la 28.1.0) :

```bash
sudo wget -O /usr/local/bin/gitea https://github.com/go-gitea/gitea/releases/download/v28.1.0/gitea-28.1.0-linux-amd64
sudo chmod +x /usr/local/bin/gitea
gitea --version
```

### 4. Créer le service systemd

`/etc/systemd/system/gitea.service` :

```ini
[Unit]
Description=Gitea
After=network.target

[Service]
Type=simple
User=git
Group=git
WorkingDirectory=/var/lib/gitea
ExecStart=/usr/local/bin/gitea web --config /etc/gitea/app.ini
Restart=always
Environment=USER=git HOME=/home/git GITEA_WORK_DIR=/var/lib/gitea

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now gitea
sudo ufw allow 3000/tcp
```

### 5. Assistant de configuration

Ouvrir `http://<adresse-du-serveur>:3000` :

- type de base : **SQLite3** (ou MySQL/PostgreSQL) ;
- **URL de base du site** : `http://<adresse-du-serveur>:3000/` ;
- créer le **compte administrateur** dans la section « Paramètres de l'administrateur ».

Gitea écrit alors sa configuration dans `/etc/gitea/app.ini`. Ensuite, verrouiller les droits sur le dossier :

```bash
sudo chmod 750 /etc/gitea
sudo chmod 640 /etc/gitea/app.ini
```

## Vérification

```bash
systemctl status gitea
curl -I http://localhost:3000
```

Créer un dépôt, puis le cloner en HTTP et en SSH (`git@<serveur>:utilisateur/depot.git`) après avoir ajouté sa clé SSH dans *Paramètres → Clés SSH / GPG*.

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/gitea/app.ini` | Configuration |
| `/var/lib/gitea/data/` | Dépôts, base SQLite, pièces jointes |
| `/var/lib/gitea/log/` | Journaux |

## Dépannage

- Sauvegarde complète : `sudo -u git gitea dump -c /etc/gitea/app.ini`.
- Journal : `journalctl -u gitea -f`.

## Points d'attention

- Le script n'installe pas `git`, dont Gitea a besoin pour fonctionner.
- Le script installe Gitea 1.20.0, une version ancienne qui ne reçoit plus de correctifs de sécurité. Le fichier de service qu'il crée contient la clé `RestartPolicy=always`, qui n'existe pas dans systemd (ignorée avec un avertissement).
- Après l'assistant, `/etc/gitea` reste modifiable par l'utilisateur `git`. Remettre des droits plus stricts (étape 5).

## Sources

- [Installer Gitea depuis le binaire](https://docs.gitea.com/installation/install-from-binary)
- [Versions publiées](https://github.com/go-gitea/gitea/releases)
