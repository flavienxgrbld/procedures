# Synchronisation vers Backblaze B2 — procédure

## Description

Backblaze B2 est un stockage objet en ligne, peu coûteux, adapté aux sauvegardes externalisées. Cette procédure synchronise un dossier local vers un bucket B2 avec rclone et automatise l'envoi chaque nuit.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu (rclone existe pour toutes les distributions) |
| **Outil** | rclone |
| **Ports** | Aucun port entrant (connexions sortantes HTTPS) |
| **Script** | `install_backblaze_sync.sh` |

## Prérequis

- Un compte Backblaze avec un **bucket B2** créé et une **clé d'application** (`keyID` et `applicationKey`), générée dans *App Keys* et limitée à ce bucket.
- Un accès root et une connexion Internet.

## Installation automatique

Le bucket et la clé d'application doivent exister (voir les prérequis). Le script installe rclone, déclare le stockage `b2` dans `/root/.config/rclone/rclone.conf` (droits 600), teste l'accès au bucket, affiche une simulation (`--dry-run`) puis crée un service et un minuteur systemd qui lancent l'envoi chaque nuit.

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/backblaze_sync
sudo B2_KEY_ID=<keyID> B2_APP_KEY=<applicationKey> B2_BUCKET=mon-bucket SOURCE_DIR=/srv/donnees \
     bash install_backblaze_sync.sh
```

| Variable | Rôle | Défaut |
|---|---|---|
| `B2_KEY_ID`, `B2_APP_KEY` | Clé d'application Backblaze | obligatoires |
| `B2_BUCKET` | Bucket de destination | obligatoire |
| `SOURCE_DIR` | Dossier local à envoyer | obligatoire |
| `B2_PATH` | Sous-dossier dans le bucket | nom court de la machine |
| `RCLONE_MODE` | `sync` (miroir : supprime à destination) ou `copy` (n'efface jamais) | `sync` |
| `SYNC_TIME` | Heure du lancement quotidien | `02:00` |

Commandes utiles ensuite : `sudo systemctl start backblaze-sync.service` (envoi immédiat), `systemctl list-timers backblaze-sync.timer`, journal `/var/log/rclone-b2.log`.

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

- En mode `sync`, un fichier supprimé localement est aussi supprimé dans B2 à la synchronisation suivante. Le script règle `hard_delete = false` : B2 garde alors une version masquée du fichier, récupérable tant que les règles de cycle de vie (lifecycle) du bucket la conservent.
- Pour chiffrer les données avant l'envoi, ajouter un stockage rclone de type `crypt` au-dessus de `b2:` et l'utiliser comme destination.
- La clé d'application est stockée en clair dans `rclone.conf` (lisible par root uniquement) : la limiter au seul bucket concerné lors de sa création.
- Relu et mis à jour le 12/11/2026.

## Sources

- [rclone — Backblaze B2](https://rclone.org/b2/)
- [Backblaze B2 — documentation](https://www.backblaze.com/docs/cloud-storage)
