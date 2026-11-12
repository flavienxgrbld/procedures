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

Le script choisit la méthode selon le système : PPA officiel `team-xbmc` sur Ubuntu, dépôts officiels sur Debian et Arch, RPM Fusion sur Fedora (et RHEL avec EPEL). Il prévient si la machine n'a pas d'interface graphique.

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

- Kodi est une application graphique : il s'installe sur le poste relié à la télévision, pas sur un serveur sans écran. Pour un serveur multimédia, voir `jellyfin`, `emby` ou `plex`.
- Activer la télécommande HTTP seulement avec un identifiant et un mot de passe : sinon, toute machine du réseau peut piloter Kodi.
- Sur openSUSE, Kodi vient du dépôt Packman (non géré par le script).
- Relu et mis à jour le 12/11/2026.

## Sources

- [Wiki Kodi — installation sous Linux](https://kodi.wiki/view/HOW-TO:Install_Kodi_for_Linux)
- [PPA team-xbmc](https://launchpad.net/~team-xbmc/+archive/ubuntu/ppa)
