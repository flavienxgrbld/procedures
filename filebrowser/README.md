# File Browser — procédure d'installation

## Description

File Browser est un gestionnaire de fichiers web : il donne accès à un dossier du serveur depuis un navigateur (envoi, téléchargement, renommage, édition, partage par lien) avec des comptes utilisateurs. Cette procédure l'installe à partir du binaire officiel, sous forme de service systemd.

| | |
|---|---|
| **Systèmes** | Linux 64 bits avec systemd |
| **Méthode** | Binaire officiel (GitHub) |
| **Ports** | 8080/tcp (par défaut) |
| **Script** | `install_filebrowser.sh` |

## Prérequis

- Un accès root et une connexion Internet.
- Le dossier à partager (ici `/srv/partage`).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/filebrowser
sudo bash install_filebrowser.sh
```

Lire les points d'attention : la configuration du script reste incomplète.

## Installation manuelle

### 1. Installer le binaire

```bash
curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | sudo bash
filebrowser version
```

Le binaire est placé dans `/usr/local/bin/filebrowser`.

### 2. Créer un utilisateur et les dossiers

```bash
sudo useradd -r -s /usr/sbin/nologin filebrowser
sudo mkdir -p /etc/filebrowser /var/lib/filebrowser /srv/partage
sudo chown -R filebrowser:filebrowser /var/lib/filebrowser /srv/partage
```

### 3. Écrire la configuration

`/etc/filebrowser/settings.json` :

```json
{
  "port": 8080,
  "address": "0.0.0.0",
  "database": "/var/lib/filebrowser/filebrowser.db",
  "root": "/srv/partage",
  "log": "stdout"
}
```

### 4. Créer le service systemd

`/etc/systemd/system/filebrowser.service` :

```ini
[Unit]
Description=File Browser
After=network.target

[Service]
User=filebrowser
Group=filebrowser
ExecStart=/usr/local/bin/filebrowser -c /etc/filebrowser/settings.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now filebrowser
sudo ufw allow 8080/tcp
```

### 5. Première connexion

Ouvrir `http://<adresse-du-serveur>:8080`. Le compte administrateur est `admin`. Dans les versions récentes, son mot de passe est généré au premier démarrage et affiché dans le journal :

```bash
sudo journalctl -u filebrowser | grep -i password
```

Changer ce mot de passe dès la connexion (*Paramètres → Profil*), puis créer les comptes utilisateurs dans *Paramètres → Gestion des utilisateurs*.

## Vérification

```bash
systemctl status filebrowser
curl -I http://localhost:8080
```

## Dépannage

- Le service s'arrête aussitôt : lire l'erreur avec `journalctl -u filebrowser -n 50`. Souvent, il s'agit de droits sur la base ou le dossier racine.

## Points d'attention

- Le script lance `filebrowser -c /etc/filebrowser/filebrowser.json` sans créer ce fichier, en root et depuis le dossier `/`. File Browser utilise alors ses valeurs par défaut : sa racine devient le dossier courant, c'est-à-dire **tout le système de fichiers**, accessible avec les droits root.
- Le script ouvre le port 80, alors que File Browser écoute sur le port 8080 par défaut. Le couple `admin / admin` qu'il affiche ne vaut que pour les anciennes versions.
- La version 2.26.0 est figée dans le script ; le script officiel `get.sh` (étape 1) installe la dernière version.
- Pour un accès depuis Internet, placer File Browser derrière un proxy inverse avec HTTPS (Nginx ou Apache et `certbot`).

## Sources

- [Dépôt File Browser](https://github.com/filebrowser/filebrowser)
- [Versions publiées](https://github.com/filebrowser/filebrowser/releases)
