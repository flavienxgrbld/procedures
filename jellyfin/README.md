# Jellyfin — procédure d'installation

## Description

Jellyfin est un serveur multimédia entièrement libre : il organise films, séries, musique et photos, puis les diffuse en streaming vers un navigateur, une télévision ou un téléphone, sans compte en ligne ni abonnement. Cette procédure l'installe avec le script officiel de dépôt pour Debian et Ubuntu.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu (dépôt officiel) ; Fedora et Arch (paquets de la communauté) |
| **Méthode** | Dépôt officiel `repo.jellyfin.org` |
| **Ports** | 8096/tcp (HTTP), 8920/tcp (HTTPS), 7359/udp (découverte locale) |
| **Script** | `install_jellyfin.sh` |

## Prérequis

- Un accès root et une connexion Internet.
- Les médias accessibles depuis le serveur (disque local ou partage monté).
- Pour le transcodage matériel : un processeur graphique Intel, AMD ou NVIDIA.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/jellyfin
sudo bash install_jellyfin.sh
```

Le script télécharge le script officiel `install-debuntu.sh` dans un fichier temporaire, l'exécute (dépôt, clé et paquets Jellyfin), démarre le service et ouvre les ports. Options : `MEDIA_DIR=/srv/medias` (droit de lecture pour `jellyfin`, étape 3) et `JELLYFIN_VAAPI=oui` (groupe `render`, étape 6).

## Installation manuelle

### 1. Ajouter le dépôt et installer Jellyfin

Le script officiel ajoute le dépôt et sa clé, puis installe Jellyfin :

```bash
curl -fsSL https://repo.jellyfin.org/install-debuntu.sh -o install-debuntu.sh
less install-debuntu.sh        # relire le script avant de l'exécuter
sudo bash install-debuntu.sh
```

### 2. Vérifier le service

```bash
sudo systemctl enable --now jellyfin
systemctl status jellyfin
```

### 3. Donner accès aux médias

Jellyfin tourne sous l'utilisateur `jellyfin`, qui doit pouvoir lire les dossiers de médias :

```bash
sudo setfacl -R -m u:jellyfin:rX /srv/medias
sudo setfacl -R -d -m u:jellyfin:rX /srv/medias   # aussi pour les futurs fichiers
```

### 4. Ouvrir le pare-feu

```bash
sudo ufw allow 8096/tcp
sudo ufw allow 7359/udp
```

### 5. Assistant de configuration

Ouvrir `http://<adresse-du-serveur>:8096` et suivre l'assistant :

1. langue d'affichage ;
2. compte administrateur ;
3. bibliothèques : type de contenu (Films, Séries, Musique), dossier, langue des métadonnées ;
4. autoriser l'accès à distance si besoin.

### 6. (Optionnel) Transcodage matériel

Dans *Tableau de bord → Lecture → Transcodage*, choisir l'accélération (Intel QSV ou VA-API, NVIDIA NVENC). Avec VA-API, ajouter `jellyfin` au groupe `render` :

```bash
sudo usermod -aG render jellyfin
sudo systemctl restart jellyfin
```

## Vérification

```bash
curl -I http://localhost:8096
```

Lire une vidéo depuis le navigateur. *Tableau de bord → Activité* montre si elle est lue directement ou transcodée.

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/jellyfin/` | Configuration du serveur |
| `/var/lib/jellyfin/` | Base de données, métadonnées, utilisateurs |
| `/var/log/jellyfin/` | Journaux |

## Dépannage

- **Bibliothèque vide** : `jellyfin` ne peut pas lire les dossiers (étape 3).
- Journal : `journalctl -u jellyfin -f`.

## Points d'attention

- Le premier compte créé dans l'assistant devient administrateur : terminer l'assistant dès l'installation.
- Sur Fedora, Jellyfin s'installe par les dépôts RPM Fusion ; sur Arch, avec le paquet `jellyfin-server` : le script ne gère que Debian et Ubuntu.
- Pour un accès depuis Internet, passer par un proxy inverse HTTPS plutôt que d'exposer le port 8096.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Installer Jellyfin sur Linux](https://jellyfin.org/docs/general/installation/linux/)
- [Accélération matérielle](https://jellyfin.org/docs/general/post-install/transcoding/hardware-acceleration/)
