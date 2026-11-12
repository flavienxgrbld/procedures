# LXD / Incus — procédure d'installation

## Description

LXD est un gestionnaire de conteneurs système et de machines virtuelles : chaque conteneur se comporte comme une machine Linux complète, légère et rapide à créer. Incus est son successeur communautaire, maintenu par les auteurs d'origine et fourni par Debian. Cette procédure installe LXD sur Ubuntu (snap) ou Incus sur Debian, puis crée un premier conteneur.

| | |
|---|---|
| **Systèmes** | Ubuntu (LXD via snap), Debian 12/13 (Incus) |
| **Méthode** | Snap `lxd` ou paquet `incus` |
| **Ports** | Aucun par défaut (8443/tcp si l'API est exposée sur le réseau) |
| **Script** | `install_lxd.sh` |

## Prérequis

- Un accès root.
- Pour les machines virtuelles : la virtualisation matérielle activée (Intel VT-x ou AMD-V).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/lxd
sudo bash install_lxd.sh
```

Le script choisit l'outil selon le système : **LXD** en snap sur Ubuntu, **Incus** sur Debian (depuis `bookworm-backports` sur Debian 12, dépôts principaux sur Debian 13). Il fait une initialisation minimale (stockage `dir`, pont réseau) si rien n'est encore configuré, puis ajoute l'utilisateur qui a lancé `sudo` au groupe d'administration (`lxd` ou `incus-admin`).

## Installation manuelle

### Ubuntu : LXD

```bash
sudo snap install lxd
sudo usermod -aG lxd $USER
newgrp lxd
lxd init --minimal
```

### Debian : Incus

```bash
sudo apt update
sudo apt install -y incus          # Debian 13
# Debian 12 : echo "deb http://deb.debian.org/debian bookworm-backports main" | sudo tee /etc/apt/sources.list.d/backports.list
#             sudo apt update && sudo apt install -y -t bookworm-backports incus
sudo usermod -aG incus-admin $USER
newgrp incus-admin
incus admin init --minimal
```

Les commandes sont identiques : `lxc` pour LXD, `incus` pour Incus.

### Créer et utiliser un conteneur

```bash
lxc launch ubuntu:24.04 web1          # Incus : incus launch images:debian/12 web1
lxc list
lxc exec web1 -- apt update
lxc shell web1
```

### Créer une machine virtuelle

```bash
lxc launch ubuntu:24.04 vm1 --vm
```

### Commandes utiles

| Commande | Rôle |
|---|---|
| `lxc stop web1` / `lxc start web1` | Arrêter / démarrer |
| `lxc snapshot web1 avant-maj` | Créer un instantané |
| `lxc restore web1 avant-maj` | Revenir à l'instantané |
| `lxc delete web1 --force` | Supprimer |
| `lxc config set web1 limits.memory 1GiB` | Limiter la mémoire |

## Vérification

```bash
lxc info
lxc list
```

Le conteneur doit apparaître à l'état `RUNNING` avec une adresse IPv4 sur le pont `lxdbr0` (`incusbr0` pour Incus).

## Dépannage

- **« permission denied » sur le socket** : l'utilisateur n'est pas dans le groupe `lxd` (ou `incus-admin`), ou ne s'est pas reconnecté.
- **Pas d'accès Internet dans le conteneur** : `ufw` bloque le pont. Autoriser le trafic : `sudo ufw allow in on lxdbr0` et `sudo ufw route allow in on lxdbr0`.

## Points d'attention

- Le groupe `lxd` (ou `incus-admin`) donne l'équivalent des droits root sur la machine : le réserver aux administrateurs.
- L'initialisation minimale utilise un stockage « dir » (simple dossier). Pour des instantanés rapides, relancer `lxd init` (ou `incus admin init`) et choisir ZFS ou Btrfs.
- Sur Debian 12, Incus vient du dépôt `bookworm-backports` : le script l'ajoute.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Installer LXD](https://documentation.ubuntu.com/lxd/latest/installing/)
- [Installer Incus](https://linuxcontainers.org/incus/docs/main/installing/)
