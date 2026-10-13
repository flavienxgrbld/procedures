# Synchronisation vers Backblaze B2 — procédure

## Description

Backblaze B2 est un stockage objet en ligne, peu coûteux, adapté aux sauvegardes externalisées. Cette procédure synchronise un dossier local vers un bucket B2 avec rclone et automatise l'envoi chaque nuit.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu (rclone existe pour toutes les distributions) |
| **Outil** | rclone |
| **Ports** | Aucun port entrant (connexions sortantes HTTPS) |
| **Script** | `install_backblaze_sync.sh` (voir les points d'attention) |

## Prérequis

- Un compte Backblaze avec un **bucket B2** créé et une **clé d'application** (`keyID` et `applicationKey`), générée dans *App Keys* et limitée à ce bucket.
- Un accès root et une connexion Internet.

## Installation manuelle

### 1. Installer rclone

```bash
sudo apt update
sudo apt install -y rclone
rclone version
```

Pour la dernière version : `curl https://rclone.org/install.sh | sudo bash`.

### 2. Déclarer le stockage B2

```bash
rclone config
```

Répondre :

1. `n` (nouveau stockage) et nom : `b2`
2. Type de stockage : `b2` (Backblaze B2)
3. `account` : le **keyID**
4. `key` : l'**applicationKey**
5. Laisser les autres options par défaut et valider.

Vérifier l'accès :

```bash
rclone lsd b2:
```

### 3. Lancer une première synchronisation

Toujours tester avec `--dry-run` : `sync` supprime à destination les fichiers absents de la source.

```bash
rclone sync /srv/donnees b2:mon-bucket/serveur1 --dry-run --progress
rclone sync /srv/donnees b2:mon-bucket/serveur1 --progress
```

Pour ne jamais supprimer côté B2, utiliser `rclone copy` au lieu de `rclone sync`.

### 4. Automatiser chaque nuit

```bash
sudo crontab -e
```

```cron
0 2 * * * rclone sync /srv/donnees b2:mon-bucket/serveur1 --log-file=/var/log/rclone-b2.log --log-level INFO
```

### 5. Restaurer des fichiers

```bash
rclone copy b2:mon-bucket/serveur1/dossier /srv/restauration --progress
```

## Vérification

```bash
rclone size b2:mon-bucket/serveur1
rclone check /srv/donnees b2:mon-bucket/serveur1
tail /var/log/rclone-b2.log
```

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `~/.config/rclone/rclone.conf` | Identifiants B2 (à protéger : `chmod 600`) |
| `/var/log/rclone-b2.log` | Journal des synchronisations |

## Points d'attention

- **Le script actuel n'installe pas d'outil Backblaze** : il installe et démarre Syncthing (service `syncthing@root`, ports 8384, 22000 et 21027), copie du script `syncthing`. Il ne doit pas être utilisé pour cette procédure ; suivre l'installation manuelle ci-dessus.
- Le script utilise `apt-key`, retiré des versions récentes de Debian et Ubuntu.
- Activer la **gestion des versions** (lifecycle) du bucket B2 permet de récupérer un fichier supprimé ou écrasé par erreur.
- Pour chiffrer les données avant l'envoi, ajouter un stockage rclone de type `crypt` au-dessus de `b2:`.

## Sources

- [rclone — Backblaze B2](https://rclone.org/b2/)
- [Backblaze B2 — documentation](https://www.backblaze.com/docs/cloud-storage)
