# Proxmox VE — procédure d'installation

## Description

Proxmox Virtual Environment (Proxmox VE) est une plateforme de virtualisation libre, basée sur Debian : elle fait tourner des machines virtuelles (KVM) et des conteneurs (LXC), avec une interface web, des sauvegardes, des instantanés, la mise en cluster et la haute disponibilité. Cette procédure installe Proxmox VE 9 sur un serveur dédié, le prépare, puis crée les machines virtuelles du labo avec le script `create_vms.sh`.

| | |
|---|---|
| **Matériel** | Serveur 64 bits avec virtualisation matérielle (Intel VT-x / AMD-V) |
| **Méthode** | ISO officielle (installation sur disque nu) ou paquets sur Debian 13 |
| **Version** | Proxmox VE 9.2 (Debian 13 « Trixie ») |
| **Ports** | 8006/tcp (interface web), 22/tcp (SSH), 3128/tcp (console SPICE) |
| **Fichiers** | `install_proxmox.sh`, `create_vms.sh`, `commandes.txt` |

## Prérequis

- La virtualisation activée dans le BIOS/UEFI (VT-x / AMD-V, et VT-d pour le passage de périphériques).
- 16 Go de RAM ou plus pour un labo avec plusieurs VM Windows (le script `create_vms.sh` en réserve environ 48 Go au total).
- Un disque dédié : **l'installation efface tout le disque choisi**.
- Une adresse IP fixe pour l'hôte (ici `192.168.1.10/24`, passerelle `192.168.1.1`).

## Installation

### 1. Préparer la clé USB

Télécharger l'ISO **Proxmox VE 9.2** sur le site officiel, puis l'écrire sur une clé USB avec Rufus (mode DD), balenaEtcher ou :

```bash
sudo dd if=proxmox-ve_9.2-1.iso of=/dev/sdX bs=1M conv=fdatasync status=progress
```

### 2. Installer

Démarrer sur la clé, choisir **Install Proxmox VE (Graphical)**, puis :

| Écran | Choix |
|---|---|
| Disque cible | Le disque dédié (ext4 ou ZFS en RAID1 si deux disques) |
| Pays / fuseau / clavier | France / Europe/Paris / French |
| Mot de passe root et e-mail | Mot de passe fort, adresse pour les alertes |
| Réseau | Interface de gestion, nom `pve.lab.local`, IP `192.168.1.10/24`, passerelle, DNS |

Au redémarrage, l'interface est accessible sur `https://192.168.1.10:8006` (utilisateur `root`, royaume *Linux PAM*).

### Variante : installation sur un Debian 13 existant

Proxmox VE peut aussi s'installer sur une Debian 13 minimale, en suivant le guide officiel « Install Proxmox VE on Debian 13 Trixie » (dépôt Proxmox, noyau `proxmox-default-kernel`, puis `proxmox-ve`).

## Préparation après installation

### 3. Configurer les dépôts sans abonnement

Sans abonnement, désactiver les dépôts *enterprise*, sinon `apt update` échoue. Dans l'interface : *Nœud → Mises à jour → Dépôts* :

1. désactiver `pve-enterprise` et `ceph enterprise` ;
2. **Ajouter → No-Subscription**.

Puis mettre à jour :

```bash
apt update && apt full-upgrade -y
```

### 4. Vérifier le réseau

Le pont `vmbr0`, créé à l'installation, relie les VM au réseau physique (*Nœud → Système → Réseau*). Pour un réseau de labo isolé, créer un second pont `vmbr1` sans port physique, routé par une VM pare-feu (pfSense, OpenWrt).

### 5. Ajouter les ISO

*Stockage `local` → Images ISO → Téléverser*, ou directement :

```bash
cd /var/lib/vz/template/iso
wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.7.0-amd64-netinst.iso   # nom à adapter à la version courante
```

Pour les VM Windows, ajouter aussi l'ISO des pilotes **VirtIO** (`virtio-win.iso`).

## Créer les machines virtuelles du labo

Le script `create_vms.sh` crée cinq VM prédéfinies :

| ID | Nom | Système | vCPU | RAM | Disque | Méthode |
|---|---|---|---|---|---|---|
| 101 | SRV-AD1EX | Windows Server 2022 | 4 | 24 Go | 120 Go | ISO |
| 102 | SRV-AD2 | Windows Server 2022 | 2 | 8 Go | 120 Go | ISO |
| 103 | SRV-GLPI | Ubuntu (cloud-init) | 2 | 4 Go | 50 Go | modèle 9000, IP `192.168.1.103/24` |
| 104 | SRV-ZABBIX | Ubuntu (cloud-init) | 2 | 4 Go | 50 Go | modèle 9000, IP `192.168.1.104/24` |
| 110 | W11-CLIENT | Windows 11 | 2 | 8 Go | 80 Go | ISO |

```bash
scp create_vms.sh root@192.168.1.10:/root/
ssh root@192.168.1.10
bash /root/create_vms.sh
```

Avant de le lancer, adapter en tête du script les identifiants, la mémoire, les adresses IP, les noms d'ISO (`VM1_ISO_NAME`…) et le stockage (`local-lvm`). Pour les VM Linux, le script télécharge une image cloud Ubuntu et en fait un modèle (ID `9000`), réutilisé si `AUTO_RECREATE_TEMPLATE=0`.

### Créer une VM à la main

Dans l'interface : **Créer VM**, puis renseigner l'ID et le nom, l'ISO, le disque (bus VirtIO SCSI, cache *Write back*), le CPU (type `host`), la mémoire et le réseau (`vmbr0`, modèle VirtIO). Pour Windows, charger le pilote VirtIO depuis le second lecteur pendant l'installation.

## Sauvegardes

*Centre de données → Sauvegarde → Ajouter* : planifier une sauvegarde nocturne des VM (mode *Snapshot*, compression ZSTD) vers un stockage dédié (disque, NFS ou Proxmox Backup Server). En ligne de commande :

```bash
vzdump 103 --mode snapshot --compress zstd --storage local
```

## Vérification

```bash
pveversion -v
systemctl status pve-cluster pvedaemon pveproxy
qm list
pvesm status
```

## Commandes utiles

L'aide-mémoire complet se trouve dans [`commandes.txt`](commandes.txt) : services, `qm` (VM), `pct` (conteneurs), stockage, réseau, sauvegardes.

| Commande | Rôle |
|---|---|
| `qm list` / `pct list` | Lister VM / conteneurs |
| `qm start 103` / `qm shutdown 103` | Démarrer / arrêter proprement |
| `qm snapshot 103 avant-maj` | Instantané |
| `qm clone 9000 105 --name SRV-WEB --full` | Cloner le modèle cloud-init |

## Points d'attention

- `install_proxmox.sh` n'installe rien : il affiche les étapes à suivre. Il indique Debian 12 et « pas d'installation sur OS existant » ; or la version actuelle, Proxmox VE 9, repose sur Debian 13, et l'installation sur une Debian existante est prise en charge (guide officiel).
- `create_vms.sh` réserve 24 Go de RAM à SRV-AD1EX : sur un hôte de 32 Go, réduire `VM1_MEMORY` avant de lancer le script.
- Le modèle cloud-init du script utilise une image Ubuntu 22.04 ou 24.04 : penser à définir l'utilisateur et la clé SSH (`ciuser`, `sshkeys`) pour pouvoir se connecter aux VM clonées.

## Sources

- [Documentation Proxmox VE](https://pve.proxmox.com/pve-docs/)
- [Dépôts de paquets](https://pve.proxmox.com/wiki/Package_Repositories)
- [Installer Proxmox VE sur Debian 13](https://pve.proxmox.com/wiki/Install_Proxmox_VE_on_Debian_13_Trixie)
