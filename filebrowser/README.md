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

Le script installe la dernière version avec le script officiel `get.sh`, crée l'utilisateur système `filebrowser`, la base `/var/lib/filebrowser/filebrowser.db` et le dossier partagé `/srv/partage`, définit lui-même le mot de passe du compte `admin` (enregistré dans `/root/filebrowser_identifiants.txt`) puis crée un service systemd restreint à ces deux dossiers. Variables facultatives : `FB_ROOT`, `FB_PORT`, `FB_ADMIN_PASS` (12 caractères minimum).

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

- Le service tourne sous l'utilisateur `filebrowser` : il ne voit que le dossier partagé, et les fichiers déposés lui appartiennent. Pour partager un dossier existant, lui donner les droits (`chown` ou ACL).
- Pour un accès depuis Internet, placer File Browser derrière un proxy inverse avec HTTPS (Nginx ou Apache et `certbot`).
- Relu et mis à jour le 12/11/2026 (File Browser 2.63).

## Sources

- [Dépôt File Browser](https://github.com/filebrowser/filebrowser)
- [Versions publiées](https://github.com/filebrowser/filebrowser/releases)
