# FOG Project — procédure d'installation

## Description

FOG Project est une solution libre de clonage et de déploiement d'images de postes par le réseau (démarrage PXE). Elle sert à capturer l'image d'un poste de référence, puis à la déployer sur un parc entier, et fait aussi l'inventaire et le suivi des postes. Cette procédure installe le serveur FOG avec son installateur officiel.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu, Rocky/AlmaLinux (voir la liste de l'installateur) |
| **Méthode** | Installateur officiel `bin/installfog.sh` (dépôt GitHub) |
| **Dossier** | `/opt/fogproject` |
| **Ports** | 80/443 (interface), 69/udp (TFTP), 67/udp (DHCP si FOG le fournit), 21 (FTP) |
| **Script** | `install_fog_project.sh` |

## Prérequis

- Un serveur dédié avec une **adresse IP fixe** sur le réseau des postes à déployer.
- Un disque assez grand pour stocker les images (plusieurs dizaines de Go par image).
- Décider qui fournit le DHCP : **FOG lui-même**, ou le **serveur DHCP existant** configuré avec les options PXE (options 66 et 67).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/fog_project
sudo bash install_fog_project.sh
```

Le script installe les outils de base, clone le dépôt officiel dans `/opt/fogproject`, ouvre les ports, puis lance l'installateur officiel. Ce dernier pose les questions de l'étape 3.

Variables disponibles : `FOG_REPO_URL`, `FOG_INSTALLER` et `FOG_BASE_DIR` (par défaut `/opt/fogproject`).

## Installation manuelle

### 1. Fixer l'adresse IP du serveur

Configurer une IP statique (par exemple `192.168.10.5/24`) dans `/etc/network/interfaces` ou Netplan, puis redémarrer le réseau.

### 2. Récupérer FOG

```bash
sudo apt update
sudo apt install -y git
sudo git clone https://github.com/FOGProject/fogproject.git /opt/fogproject
cd /opt/fogproject/bin
```

### 3. Lancer l'installateur officiel

```bash
sudo ./installfog.sh
```

Réponses habituelles :

| Question | Réponse |
|---|---|
| Distribution | celle détectée |
| Installation type | `N` (Normal Server) |
| Interface réseau | l'interface sur le réseau des postes |
| Router address for DHCP | `y`, l'adresse de la passerelle |
| DNS for DHCP | `y`, l'adresse du DNS |
| Use FOG as DHCP server | `y` s'il n'y a pas d'autre DHCP, sinon `n` |
| Additional language packs | `n` |
| HTTPS | `n` pour un labo |

L'installateur installe Apache, PHP, MariaDB, TFTP, NFS et FTP. Il demande ensuite d'ouvrir l'interface web pour mettre à jour le schéma de la base, puis de revenir valider dans le terminal.

### 4. Si un autre serveur DHCP est utilisé

Sur ce serveur DHCP, ajouter les options PXE :

- option 66 (*next-server*) : adresse du serveur FOG ;
- option 67 (*filename*) : `undionly.kpxe` pour les postes en BIOS, `ipxe.efi` pour les postes en UEFI.

### 5. Première connexion

Ouvrir `http://<adresse-du-serveur>/fog/management`. L'identifiant par défaut est `fog`, avec le mot de passe `password`, **à changer immédiatement**.

## Vérification

```bash
systemctl status apache2 mariadb tftpd-hpa nfs-kernel-server vsftpd
```

Démarrer un poste en PXE sur le réseau : le menu FOG doit apparaître. Choisir *Perform Full Host Registration* pour inscrire le poste.

## Utilisation type

1. Créer une **image** (*Image Management → Create New Image*).
2. Associer le poste de référence à cette image, puis lancer une tâche **Capture**.
3. Pour déployer, associer les postes cibles à l'image, puis lancer une tâche **Deploy** (individuelle ou sur un groupe).

## Dépannage

- **« PXE-E32 TFTP open timeout »** : le TFTP n'est pas joignable, ou l'option 66 pointe vers une mauvaise adresse.
- Journaux : `/var/log/fog/` et `/var/log/apache2/error.log`.

## Points d'attention

- Si le gestionnaire de paquets n'est pas géré, ou si l'installateur est introuvable, le script appelle la fonction `fatal`, qui n'existe pas dans la bibliothèque commune : il s'arrête avec « command not found » au lieu d'un message clair.
- Deux serveurs DHCP actifs sur le même réseau provoquent des conflits : choisir l'un ou l'autre à l'étape 3.

## Sources

- [Documentation FOG Project](https://docs.fogproject.org/)
- [Dépôt FOG Project](https://github.com/FOGProject/fogproject)
