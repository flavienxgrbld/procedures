# Emby — procédure d'installation

## Description

Emby Server est un serveur multimédia qui organise films, séries, musique et photos, puis les diffuse en streaming vers un navigateur, une télévision, un téléphone ou une console. Cette procédure installe le paquet officiel Debian/Ubuntu.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu (64 bits) |
| **Méthode** | Paquet `.deb` officiel (GitHub) |
| **Ports** | 8096/tcp (HTTP), 8920/tcp (HTTPS) |
| **Script** | `install_emby.sh` |

## Prérequis

- Un accès root et une connexion Internet.
- Les médias accessibles depuis le serveur (disque local ou partage réseau monté).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/emby
sudo bash install_emby.sh
```

Le script récupère la dernière version stable publiée sur GitHub (ou `EMBY_VERSION`) pour l'architecture de la machine, installe le paquet et démarre le service `emby-server`. Avec `MEDIA_DIR`, il donne aussi à Emby le droit de lire le dossier de médias (étape 3) :

```bash
sudo MEDIA_DIR=/srv/medias bash install_emby.sh
```

## Installation manuelle

### 1. Télécharger le paquet

Récupérer le fichier `emby-server-deb_<version>_amd64.deb` sur la page des versions d'Emby (prendre la dernière version **sans** la mention *Pre-release* ; `arm64` sur un Raspberry Pi 64 bits) :

```bash
cd /tmp
wget https://github.com/MediaBrowser/Emby.Releases/releases/download/<version>/emby-server-deb_<version>_amd64.deb
```

### 2. Installer

```bash
sudo apt install -y ./emby-server-deb_*_amd64.deb
```

Le service `emby-server` est créé et démarré automatiquement.

### 3. Donner accès aux médias

Emby tourne sous l'utilisateur `emby`, qui doit pouvoir lire les dossiers de médias :

```bash
sudo setfacl -R -m u:emby:rX /srv/medias
sudo setfacl -R -d -m u:emby:rX /srv/medias   # aussi pour les futurs fichiers
```

À défaut d'ACL, ajouter `emby` au groupe propriétaire des fichiers.

### 4. Ouvrir le pare-feu

```bash
sudo ufw allow 8096/tcp
```

### 5. Assistant de configuration

Ouvrir `http://<adresse-du-serveur>:8096` et suivre l'assistant : langue, compte administrateur, ajout des bibliothèques (type de contenu et dossier), puis langue des métadonnées.

## Vérification

```bash
systemctl status emby-server
curl -I http://localhost:8096
```

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/var/lib/emby/` | Base de données, métadonnées, configuration |
| `/var/lib/emby/logs/` | Journaux |
| `/opt/emby-server/` | Programme |

## Dépannage

- **Bibliothèque vide** : l'utilisateur `emby` n'a pas le droit de lire les dossiers (étape 3).
- Journal : `journalctl -u emby-server -f`.

## Mise à jour

Télécharger le nouveau `.deb` et relancer `sudo apt install -y ./emby-server-deb_*.deb`.

## Points d'attention

- Emby n'a plus de dépôt APT : les mises à jour se font en relançant le script (ou en installant le nouveau `.deb`).
- Certaines fonctions (transcodage matériel, téléchargements hors ligne, applications TV) nécessitent l'abonnement Emby Premiere. Pour une solution entièrement libre, voir la procédure Jellyfin.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Emby pour Linux](https://emby.media/linux-server.html)
- [Versions publiées](https://github.com/MediaBrowser/Emby.Releases/releases)
