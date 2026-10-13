# Kodi — procédure d'installation

## Description

Kodi est un centre multimédia libre qui transforme un ordinateur, un mini-PC ou un Raspberry Pi en lecteur pour la télévision : films, séries, musique, photos, télévision en direct et extensions. C'est une application cliente avec interface graphique, pas un service serveur.

| | |
|---|---|
| **Systèmes** | Ubuntu (PPA officiel), Debian, Fedora (RPM Fusion), Arch |
| **Méthode** | Paquets de la distribution ou PPA `team-xbmc` |
| **Ports** | 8080/tcp (télécommande web, si activée) |
| **Script** | `install_kodi.sh` |

## Prérequis

- Un environnement graphique (bureau) et un écran.
- Un accès root pour l'installation.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/kodi
sudo bash install_kodi.sh
```

## Installation manuelle

### Ubuntu (dernière version via le PPA officiel)

```bash
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:team-xbmc/ppa
sudo apt update
sudo apt install -y kodi
```

### Debian

Kodi est dans les dépôts officiels :

```bash
sudo apt update
sudo apt install -y kodi
```

### Fedora

Kodi est fourni par RPM Fusion :

```bash
sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install -y kodi
```

### Lancer Kodi

Depuis le menu des applications, ou :

```bash
kodi
```

## Configuration

1. **Ajouter des médias** : *Vidéos → Fichiers → Ajouter des vidéos*, puis choisir le dossier local ou le partage réseau (SMB, NFS) et le type de contenu (Films, Séries) pour récupérer les métadonnées.
2. **Langue** : *Paramètres → Interface → Région → Langue*.
3. **Télécommande depuis un téléphone** : *Paramètres → Services → Contrôle*, activer « Autoriser le contrôle à distance via HTTP » avec un identifiant et un mot de passe, puis utiliser l'application Kore (Android) ou Official Kodi Remote (iOS).

## Vérification

```bash
kodi --version
```

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `~/.kodi/userdata/` | Paramètres, bibliothèque, sources |
| `~/.kodi/addons/` | Extensions installées |
| `~/.kodi/temp/kodi.log` | Journal |

## Points d'attention

- Le PPA `team-xbmc` utilisé par le script n'existe que pour Ubuntu : sur Debian, `add-apt-repository` échoue. Installer alors le paquet des dépôts Debian.
- Sur Fedora, le paquet `kodi` n'est pas dans les dépôts de base : il faut activer RPM Fusion avant.
- Pour un serveur multimédia sans écran, qui diffuse vers plusieurs appareils, voir plutôt les procédures `jellyfin`, `emby` ou `plex`.

## Sources

- [Wiki Kodi — installation sous Linux](https://kodi.wiki/view/HOW-TO:Install_Kodi_for_Linux)
- [PPA team-xbmc](https://launchpad.net/~team-xbmc/+archive/ubuntu/ppa)
