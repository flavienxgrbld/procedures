# Rclone — procédure d'installation

## Description

Rclone est un outil en ligne de commande qui copie, synchronise et monte des fichiers vers plus de 70 services de stockage : Google Drive, OneDrive, Dropbox, S3, Backblaze B2, SFTP, serveurs WebDAV… Il sert aux sauvegardes externalisées et aux transferts entre clouds. Cette procédure l'installe, configure un stockage et automatise une synchronisation.

| | |
|---|---|
| **Systèmes** | Toute distribution Linux (et Windows, macOS) |
| **Méthode** | Script officiel `rclone.org/install.sh` (ou paquet de la distribution) |
| **Ports** | Aucun port entrant |
| **Script** | `install_rclone.sh` |

## Prérequis

- Un accès root pour l'installation.
- Un compte sur le service de stockage visé.
- `fuse3` pour monter un stockage comme un dossier (optionnel).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/rclone
sudo bash install_rclone.sh
```

## Installation manuelle

### 1. Installer rclone

Dernière version (script officiel) :

```bash
sudo apt install -y curl unzip fuse3
curl https://rclone.org/install.sh | sudo bash
rclone version
```

Ou version de la distribution : `sudo apt install -y rclone`.

### 2. Configurer un stockage

```bash
rclone config
```

Choisir `n` (nouveau), donner un nom (par exemple `gdrive`), puis le type de stockage. Pour Google Drive ou OneDrive, rclone ouvre une authentification dans le navigateur. Sur un serveur sans navigateur, utiliser `rclone authorize "drive"` sur un poste de travail, puis coller le jeton obtenu.

```bash
rclone listremotes
rclone lsd gdrive:
```

### 3. Copier ou synchroniser

```bash
# Copier (n'efface jamais à destination)
rclone copy /srv/donnees gdrive:sauvegardes/serveur1 --progress

# Synchroniser (la destination devient identique à la source) : tester d'abord
rclone sync /srv/donnees gdrive:sauvegardes/serveur1 --dry-run
rclone sync /srv/donnees gdrive:sauvegardes/serveur1 --progress
```

### 4. Automatiser

```bash
sudo crontab -e
```

```cron
30 2 * * * rclone sync /srv/donnees gdrive:sauvegardes/serveur1 --log-file=/var/log/rclone.log --log-level INFO
```

### 5. (Optionnel) Monter un stockage comme un dossier

```bash
mkdir -p ~/gdrive
rclone mount gdrive: ~/gdrive --vfs-cache-mode writes --daemon
```

## Vérification

```bash
rclone check /srv/donnees gdrive:sauvegardes/serveur1
rclone size gdrive:sauvegardes/serveur1
```

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `~/.config/rclone/rclone.conf` | Stockages et jetons d'accès (à protéger : `chmod 600`) |

## Points d'attention

- Le script installe le paquet `fuse`, alors que les versions récentes de rclone utilisent `fuse3` pour `rclone mount`.
- Il crée `~/.config/rclone` pour l'utilisateur **root** : la configuration créée ensuite par un autre utilisateur se trouve dans le dossier personnel de cet utilisateur. Lancer `rclone config` avec le compte qui exécutera les synchronisations.
- `rclone config password` permet de chiffrer le fichier de configuration, qui contient des jetons d'accès aux comptes.
- Pour Backblaze B2, voir aussi la procédure `backblaze_sync`.

## Sources

- [Installer rclone](https://rclone.org/install/)
- [Documentation rclone](https://rclone.org/docs/)
