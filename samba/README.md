# Samba — procédure d'installation

## Description

Samba permet à un serveur Linux de partager des dossiers avec les postes Windows, macOS et Linux via le protocole SMB/CIFS, avec des droits par utilisateur et par groupe. Cette procédure installe un serveur de fichiers autonome, avec le script interactif du dépôt, puis une configuration sécurisée par comptes.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu, RHEL/Fedora, openSUSE, Arch |
| **Méthode** | Paquets de la distribution + configuration `smb.conf` |
| **Ports** | 445/tcp (SMB) ; 137-138/udp et 139/tcp (NetBIOS, anciens clients) |
| **Script** | `install_samba.sh` |

## Prérequis

- Un accès root et une adresse IP fixe.
- Les comptes et groupes des personnes qui accéderont aux partages.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/samba
sudo bash install_samba.sh
```

Le script propose trois profils :

| Profil | Contenu |
|---|---|
| 1 — Basique (par défaut) | Partage `public` dans `/srv/samba/public`, accès invité en écriture |
| 2 — Standard | Nom et chemin du partage demandés, mêmes droits que le profil basique |
| 3 — Avancé | Toutes les valeurs demandées une à une |

Sans terminal interactif, il utilise les variables d'environnement, par exemple :

```bash
sudo SMB_SHARE_NAME=commun SMB_SHARE_PATH=/srv/samba/commun SMB_GUEST_OK=no SMB_FORCE_USER=nobody bash install_samba.sh < /dev/null
```

Variables disponibles : `SMB_WORKGROUP`, `SMB_SERVER_STRING`, `SMB_SECURITY`, `SMB_SHARE_NAME`, `SMB_SHARE_PATH`, `SMB_READ_ONLY`, `SMB_GUEST_OK`, `SMB_BROWSEABLE`, `SMB_FORCE_USER`, `SMB_DIR_OWNER`, `SMB_DIR_GROUP`, `SMB_DIR_PERMS`, `SMB_FILE_PERMS`.

Lire les points d'attention avant d'utiliser le profil par défaut.

## Installation manuelle (partage sécurisé par groupe)

### 1. Installer Samba

```bash
sudo apt update
sudo apt install -y samba smbclient
```

### 2. Créer le groupe, les comptes et le dossier

```bash
sudo groupadd compta
sudo useradd -M -s /usr/sbin/nologin -G compta alice
sudo smbpasswd -a alice            # mot de passe Samba de l'utilisateur
sudo mkdir -p /srv/samba/compta
sudo chown root:compta /srv/samba/compta
sudo chmod 2770 /srv/samba/compta  # le bit setgid garde le groupe sur les nouveaux fichiers
```

### 3. Configurer le partage

```bash
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.orig
sudo nano /etc/samba/smb.conf
```

Dans `[global]`, vérifier :

```ini
[global]
   workgroup = WORKGROUP
   server string = Serveur de fichiers
   security = user
   map to guest = never
   server min protocol = SMB2
```

Puis ajouter le partage à la fin du fichier :

```ini
[compta]
   path = /srv/samba/compta
   valid users = @compta
   read only = no
   browseable = yes
   create mask = 0660
   directory mask = 2770
```

### 4. Vérifier et redémarrer

```bash
testparm -s
sudo systemctl enable --now smbd
sudo systemctl restart smbd
sudo ufw allow from 192.168.1.0/24 to any app Samba
```

### 5. Se connecter depuis un poste

- **Windows** : `\\<adresse-du-serveur>\compta` dans l'Explorateur, puis le compte `alice`.
- **Linux** : `smbclient //<adresse-du-serveur>/compta -U alice`, ou monter avec `sudo mount -t cifs //<serveur>/compta /mnt/compta -o username=alice`.

## Vérification

```bash
systemctl status smbd
smbclient -L localhost -U alice
sudo smbstatus
```

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/samba/smb.conf` | Configuration (global et partages) |
| `/var/log/samba/` | Journaux par client |

## Dépannage

- **Accès refusé** : vérifier que l'utilisateur a bien un mot de passe Samba (`sudo pdbedit -L`), qu'il est dans le groupe, et les droits Linux du dossier.
- Windows ne voit pas le serveur dans « Réseau » : la découverte réseau de Windows 10/11 ne liste plus les serveurs SMB. Saisir directement le chemin `\\serveur\partage`.

## Points d'attention

- Le profil par défaut du script crée un partage **accessible sans mot de passe, en écriture, avec `force user = root`** : tout fichier déposé appartient à root, et n'importe qui sur le réseau peut lire, modifier ou supprimer le contenu. À réserver à un test isolé ; sinon utiliser `SMB_GUEST_OK=no` et un utilisateur non privilégié, ou la configuration manuelle ci-dessus.
- Le script remplace tout `smb.conf` (une copie datée est conservée) et ouvre aussi les ports 139/udp et 445/udp, inutiles.
- Pour un **contrôleur de domaine Active Directory** sous Samba (`samba-tool domain provision`), suivre une procédure dédiée : ce script installe seulement un serveur de fichiers.

## Sources

- [Samba en serveur autonome](https://wiki.samba.org/index.php/Setting_up_Samba_as_a_Standalone_Server)
- [Page de manuel smb.conf](https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html)
