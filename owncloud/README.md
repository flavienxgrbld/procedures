# ownCloud Infinite Scale — procédure d'installation

## Description

ownCloud est une solution de partage et de synchronisation de fichiers auto-hébergée, alternative à Dropbox ou Google Drive. Sa génération actuelle, **ownCloud Infinite Scale (oCIS)**, est un binaire unique écrit en Go, sans PHP ni base de données externe. Cette procédure l'installe sous forme de service systemd.

| | |
|---|---|
| **Systèmes** | Linux 64 bits avec systemd |
| **Méthode** | Binaire officiel oCIS (GitHub), version 8.2.1 |
| **Ports** | 9200/tcp (HTTPS) |
| **Script** | `install_owncloud.sh` (ownCloud 10 classique, voir les points d'attention) |

## Prérequis

- Un accès root et une connexion Internet.
- Un disque pour les fichiers des utilisateurs (ici `/srv/ocis`).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/owncloud
sudo bash install_owncloud.sh
```

Le script vise l'ancien ownCloud 10, qu'il ne parvient pas à télécharger : suivre l'installation manuelle.

## Installation manuelle

### 1. Installer le binaire

```bash
sudo wget -O /usr/local/bin/ocis https://github.com/owncloud/ocis/releases/download/v8.2.1/ocis-8.2.1-linux-amd64
sudo chmod +x /usr/local/bin/ocis
ocis version
```

### 2. Créer l'utilisateur et les dossiers

```bash
sudo useradd -r -s /usr/sbin/nologin ocis
sudo mkdir -p /etc/ocis /srv/ocis
sudo chown ocis:ocis /etc/ocis /srv/ocis
```

### 3. Initialiser la configuration

```bash
sudo -u ocis env OCIS_CONFIG_DIR=/etc/ocis OCIS_BASE_DATA_PATH=/srv/ocis ocis init --insecure true
```

La commande crée `/etc/ocis/ocis.yaml` et **affiche le mot de passe du compte `admin`** : le noter. `--insecure true` accepte le certificat autosigné généré par oCIS (labo).

### 4. Créer le service systemd

`/etc/systemd/system/ocis.service` :

```ini
[Unit]
Description=ownCloud Infinite Scale
After=network.target

[Service]
User=ocis
Group=ocis
Environment=OCIS_CONFIG_DIR=/etc/ocis
Environment=OCIS_BASE_DATA_PATH=/srv/ocis
Environment=OCIS_URL=https://192.168.1.60:9200
Environment=PROXY_HTTP_ADDR=0.0.0.0:9200
Environment=OCIS_INSECURE=true
ExecStart=/usr/local/bin/ocis server
Restart=always

[Install]
WantedBy=multi-user.target
```

Remplacer `192.168.1.60` par l'adresse ou le nom du serveur : `OCIS_URL` doit correspondre exactement à l'adresse utilisée dans le navigateur.

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now ocis
sudo ufw allow 9200/tcp
```

### 5. Se connecter

Ouvrir `https://192.168.1.60:9200`, accepter le certificat, puis se connecter avec `admin` et le mot de passe affiché à l'étape 3. Créer ensuite les utilisateurs dans *Administration*.

Les clients de synchronisation ownCloud (Windows, macOS, Linux, Android, iOS) se connectent à la même adresse.

## Vérification

```bash
systemctl status ocis
journalctl -u ocis -n 30
```

## Points d'attention

- Le script installe l'ownCloud 10 classique depuis `download.owncloud.org/community/owncloud-latest.tar.gz`. Cette adresse redirige vers la page d'accueil du site au lieu de fournir l'archive (vérifié le 13/10/2026) : l'extraction échoue.
- Le script installe PHP 8.1, alors qu'ownCloud 10 ne fonctionne qu'avec PHP 7.4. Il nomme aussi les modules PHP `php81-gd`, etc., au lieu de `php8.1-gd` sur Debian et Ubuntu.
- En production, placer oCIS derrière un proxy inverse avec un vrai certificat (procédures `nginx` et `certbot`) et retirer `OCIS_INSECURE`.
- Pour une solution de la même famille avec un large catalogue d'applications, Nextcloud est l'autre choix courant.

## Sources

- [Documentation oCIS](https://doc.owncloud.com/ocis/next/)
- [Versions publiées](https://github.com/owncloud/ocis/releases)
