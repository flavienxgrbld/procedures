# Restic — procédure d'installation

## Description

Restic est un logiciel de sauvegarde rapide, chiffré et dédupliqué : chaque sauvegarde est un instantané complet, mais seules les données nouvelles sont stockées. Le dépôt peut être local, sur un serveur SFTP, sur un stockage S3, Backblaze B2 ou tout service géré par rclone. Cette procédure met en place une sauvegarde quotidienne avec rotation et vérification.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu, RHEL/Fedora, openSUSE, Arch |
| **Méthode** | Paquet de la distribution + script et tâche planifiée |
| **Ports** | Aucun port entrant |
| **Script** | `install_restic.sh` |

## Prérequis

- Un emplacement pour le dépôt de sauvegarde, idéalement **sur une autre machine ou un autre disque** (ici le disque monté sur `/mnt/backup`).
- Un accès root.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/restic
sudo bash install_restic.sh
```

Le script installe restic (et tente `restic self-update`), crée le mot de passe du dépôt (`/etc/restic/password`, 600), initialise le dépôt (`/mnt/backup/restic` ou `RESTIC_REPO`), écrit le script de l'étape 4 avec les variables **exportées**, puis un service et un minuteur systemd quotidiens (à la place de la tâche cron de l'étape 5). Il prévient si le dépôt local est sur le disque système. Variables facultatives : `RESTIC_REPO`, `RESTIC_PATHS`, `RESTIC_TIME`.

## Installation manuelle

### 1. Installer restic

```bash
sudo apt update
sudo apt install -y restic
sudo restic self-update        # passer à la dernière version
restic version
```

### 2. Créer le mot de passe du dépôt

```bash
sudo mkdir -p /etc/restic
openssl rand -base64 32 | sudo tee /etc/restic/password > /dev/null
sudo chmod 600 /etc/restic/password
```

**Conserver une copie de ce mot de passe en lieu sûr** (gestionnaire de mots de passe) : sans lui, les sauvegardes sont illisibles.

### 3. Initialiser le dépôt

```bash
export RESTIC_REPOSITORY=/mnt/backup/restic
export RESTIC_PASSWORD_FILE=/etc/restic/password
sudo -E restic init
```

Exemples d'autres dépôts : `sftp:sauvegarde@nas:/srv/restic`, `s3:https://s3.exemple.fr/bucket`, `rclone:gdrive:restic`.

### 4. Écrire le script de sauvegarde

`/etc/restic/backup.sh` :

```bash
#!/usr/bin/env bash
set -euo pipefail
export RESTIC_REPOSITORY=/mnt/backup/restic
export RESTIC_PASSWORD_FILE=/etc/restic/password

restic backup /etc /home /root /srv --exclude-caches
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --prune
restic check
```

```bash
sudo chmod 700 /etc/restic/backup.sh
```

### 5. Planifier

```bash
echo '0 2 * * * root /etc/restic/backup.sh >> /var/log/restic.log 2>&1' | sudo tee /etc/cron.d/restic
```

## Vérification

```bash
sudo /etc/restic/backup.sh
sudo -E restic snapshots
```

## Restaurer

```bash
# Tout un instantané dans un dossier de restauration
sudo -E restic restore latest --target /srv/restauration

# Un seul fichier
sudo -E restic restore latest --target /srv/restauration --include /etc/nginx/nginx.conf

# Parcourir les sauvegardes comme un dossier
sudo -E restic mount /mnt/restic
```

Tester une restauration régulièrement : une sauvegarde jamais restaurée n'est pas une sauvegarde vérifiée.

## Points d'attention

- **Conserver une copie du mot de passe du dépôt** hors du serveur : sans lui, les sauvegardes sont illisibles.
- Un dépôt sur le même disque que les données ne protège pas d'une panne de disque : utiliser un disque séparé, un NAS (SFTP) ou un stockage S3.
- Tester régulièrement une restauration : `restic restore latest --target /tmp/test-restauration`.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Documentation restic](https://restic.readthedocs.io/en/stable/)
- [Préparer un dépôt](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html)
