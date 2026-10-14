# OpenWrt — procédure d'installation

## Description

OpenWrt est un système d'exploitation Linux libre pour routeurs et points d'accès : il remplace le micrologiciel du constructeur et apporte pare-feu, VLAN, VPN, qualité de service et des milliers de paquets. Il s'installe sur un routeur compatible, ou en machine virtuelle x86 pour un labo. Cette procédure couvre les deux cas.

| | |
|---|---|
| **Matériel** | Routeur compatible (Table of Hardware) ou machine virtuelle x86-64 |
| **Méthode** | Image officielle `downloads.openwrt.org` (version 25.12.5) |
| **Accès** | LuCI (interface web) et SSH sur `192.168.1.1` |
| **Script** | `install_openwrt.sh` (affiche seulement des instructions) |

## Prérequis

- Routeur : vérifier sa compatibilité **modèle et révision matérielle** dans la *Table of Hardware*.
- Labo : un hyperviseur (Proxmox, VirtualBox), avec 2 cartes réseau pour la VM (LAN et WAN).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/openwrt
sudo bash install_openwrt.sh
```

Le script n'installe rien : il affiche les étapes générales et des liens. Suivre l'une des méthodes ci-dessous.

## Méthode 1 : routeur compatible

1. Sur la page du modèle dans la *Table of Hardware*, télécharger l'image **factory** (première installation depuis le micrologiciel d'origine).
2. Relier un PC au routeur par câble, puis passer par la page de mise à jour du micrologiciel du constructeur pour envoyer l'image *factory*.
3. Attendre le redémarrage (ne pas couper l'alimentation), puis ouvrir `http://192.168.1.1`.

Les mises à jour suivantes utilisent l'image **sysupgrade**, depuis LuCI (*Système → Sauvegarde / Flasher le micrologiciel*).

## Méthode 2 : machine virtuelle sur Proxmox

### 1. Télécharger et décompresser l'image

Sur l'hôte Proxmox :

```bash
cd /tmp
wget https://downloads.openwrt.org/releases/25.12.5/targets/x86/64/openwrt-25.12.5-x86-64-generic-ext4-combined-efi.img.gz
gunzip openwrt-25.12.5-x86-64-generic-ext4-combined-efi.img.gz
```

### 2. Créer la VM

```bash
qm create 200 --name openwrt --memory 512 --cores 1 --bios ovmf --machine q35 \
  --net0 virtio,bridge=vmbr1 --net1 virtio,bridge=vmbr0 --ostype l26
qm importdisk 200 openwrt-25.12.5-x86-64-generic-ext4-combined-efi.img local-lvm
qm set 200 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-200-disk-0 --boot order=scsi0 \
  --efidisk0 local-lvm:0,efitype=4m,pre-enrolled-keys=0
qm start 200
```

`net0` devient le **LAN** (`br-lan`, `192.168.1.1`), `net1` le **WAN** (DHCP). Adapter les ponts `vmbr0` et `vmbr1` à son installation.

### 3. Changer l'adresse du LAN si besoin

Dans la console de la VM :

```sh
uci set network.lan.ipaddr='192.168.50.1'
uci commit network
service network restart
```

## Configuration initiale (dans les deux cas)

1. Ouvrir `http://192.168.1.1` (LuCI) ou `ssh root@192.168.1.1`.
2. **Définir le mot de passe root** (*Système → Administration*) : il est vide à l'installation.
3. Vérifier l'accès Internet sur l'interface WAN (*Réseau → Interfaces*).
4. Mettre à jour la liste des paquets et installer les modules utiles :

```sh
apk update
apk add luci-i18n-base-fr
```

OpenWrt 25.12 utilise le gestionnaire de paquets `apk` (les versions précédentes utilisaient `opkg`).

## Vérification

```sh
ubus call system board
ping -c 3 openwrt.org
```

## Points d'attention

- Le script `install_openwrt.sh` n'installe rien sur le serveur : OpenWrt est un système complet, qui remplace celui du routeur ou s'installe dans sa propre VM.
- Flasher une image destinée à un autre modèle, ou une mauvaise révision matérielle, peut rendre le routeur inutilisable : toujours vérifier la *Table of Hardware*.

## Sources

- [Guide de démarrage OpenWrt](https://openwrt.org/docs/guide-quick-start/start)
- [Table of Hardware](https://openwrt.org/toh/start)
- [Téléchargements](https://downloads.openwrt.org/releases/)
