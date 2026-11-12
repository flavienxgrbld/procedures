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

Le script installe Git, crée l'utilisateur `git` et les dossiers, télécharge la dernière version publiée (ou `GITEA_VERSION`) pour l'architecture de la machine en vérifiant sa somme SHA-256, puis crée et démarre le service. Il reste l'assistant web (étape 5) et le verrouillage des droits sur `/etc/gitea`, que le script rappelle. Relancé, il met le binaire à jour sans toucher à la configuration. Variable facultative : `GITEA_PORT`.

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

Prendre la dernière version sur la page des versions (28.3.0 au 12/11/2026 ; Gitea est passé d'une numérotation 1.x à 28.x) :

```bash
sudo wget -O /usr/local/bin/gitea https://github.com/go-gitea/gitea/releases/download/v28.3.0/gitea-28.3.0-linux-amd64
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

- Tant que l'assistant n'a pas été validé, n'importe qui peut configurer l'instance et créer le compte administrateur : le faire dès la fin de l'installation.
- Après l'assistant, `/etc/gitea` reste modifiable par l'utilisateur `git` : remettre des droits plus stricts (étape 5).
- Pour cloner en SSH, Gitea utilise le serveur SSH du système avec le compte `git` (`git@serveur:utilisateur/depot.git`).
- Relu et mis à jour le 12/11/2026 (Gitea 28.3).

## Sources

- [Installer Gitea depuis le binaire](https://docs.gitea.com/installation/install-from-binary)
- [Versions publiées](https://github.com/go-gitea/gitea/releases)
