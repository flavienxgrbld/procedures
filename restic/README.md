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

Le script installe restic, crée `/etc/restic/backup.conf`, `/etc/restic/backup.sh` et une tâche quotidienne à 2 h. Il faut ensuite créer le fichier de mot de passe : lire les points d'attention.

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

- Le script `backup.sh` charge `RESTIC_PASSWORD_FILE` avec `source`, sans l'exporter : restic ne voit pas la variable et demande le mot de passe au clavier. Lancée par cron, la sauvegarde échoue. Il faut `export` (étape 4) ou l'option `--password-file`.
- Le script ne crée pas le fichier `/etc/restic/password` : il faut le créer avant la première exécution (étape 2).
- Il conserve le dépôt dans `/mnt/backup/restic` : s'assurer qu'un disque est bien monté à cet endroit, sinon la sauvegarde remplit le disque système et disparaît avec lui.

## Sources

- [Documentation restic](https://restic.readthedocs.io/en/stable/)
- [Préparer un dépôt](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html)
