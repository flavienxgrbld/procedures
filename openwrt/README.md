# OpenWrt — procédure d'installation

## Description

OpenWrt est un système d'exploitation Linux libre pour routeurs et points d'accès : il remplace le micrologiciel du constructeur et apporte pare-feu, VLAN, VPN, qualité de service et des milliers de paquets. Il s'installe sur un routeur compatible, ou en machine virtuelle x86 pour un labo. Cette procédure couvre les deux cas.

| | |
|---|---|
| **Matériel** | Routeur compatible (Table of Hardware) ou machine virtuelle x86-64 |
| **Méthode** | Image officielle `downloads.openwrt.org` (version 25.12.6) |
| **Accès** | LuCI (interface web) et SSH sur `192.168.1.1` |
| **Script** | `install_openwrt.sh` (crée la VM sur un hôte Proxmox, sinon affiche la méthode) |

## Prérequis

- Routeur : vérifier sa compatibilité **modèle et révision matérielle** dans la *Table of Hardware*.
- Labo : un hyperviseur (Proxmox, VirtualBox), avec 2 cartes réseau pour la VM (LAN et WAN).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/openwrt
sudo bash install_openwrt.sh
```

Lancé sur un **hôte Proxmox VE**, le script fait la méthode 2 tout seul : il télécharge l'image x86-64 (25.12.6), vérifie sa somme SHA-256 et crée la VM (UEFI, LAN sur `vmbr1`, WAN sur `vmbr0`, console série). Ailleurs, il n'installe rien et affiche la méthode 1 (routeur compatible). Variables facultatives : `OPENWRT_VERSION`, `OPENWRT_VMID`, `OPENWRT_LAN_BR`, `OPENWRT_WAN_BR`, `OPENWRT_STORAGE`.

## Vérification

```sh
ubus call system board
ping -c 3 openwrt.org
```

## Points d'attention

- Flasher une image destinée à un autre modèle, ou à une autre révision matérielle, peut rendre le routeur inutilisable : toujours vérifier la *Table of Hardware*.
- OpenWrt démarre avec le LAN en `192.168.1.1` : si ce réseau existe déjà, changer l'adresse (étape 3 de la méthode 2) avant de brancher la VM sur le réseau de production.
- Version courante le 12/11/2026 : 25.12.6.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Guide de démarrage OpenWrt](https://openwrt.org/docs/guide-quick-start/start)
- [Table of Hardware](https://openwrt.org/toh/start)
- [Téléchargements](https://downloads.openwrt.org/releases/)
