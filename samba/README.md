# Installation Samba (Serveur SMB)

## Description
Samba est un serveur SMB/CIFS qui permet de partager des fichiers entre systèmes Linux, Windows et macOS.

## Prérequis
- Ubuntu/Debian ou autre distribution Linux prise en charge
- Accès root ou sudo
- Connexion Internet
- Firewall configuré selon votre réseau

## Installation

Exécutez le script d’installation :

```bash
bash install_samba.sh
```

### Étapes détaillées
Le script `install_samba.sh` :
- met à jour les paquets nécessaires ;
- installe le paquet Samba ;
- crée un dossier de partage `/srv/samba/public` ;
- génère une configuration minimale dans `/etc/samba/smb.conf` ;
- active et démarre le service `smbd` ;
- ouvre les ports SMB dans UFW si le firewall est présent.

## Configuration du partage

### Choix du niveau de configuration
Le script propose un menu interactif au lancement :

```bash
=== Niveau de configuration SMB ===
1) Basique - partage public simple
2) Standard - nom et chemin personnalisés
3) Avancé - configuration détaillée
Choisissez un niveau [1] :
```

- Niveau 1 : configuration minimaliste, idéal pour un partage public rapide.
- Niveau 2 : nom et chemin de partage personnalisés, sans trop de détails.
- Niveau 3 : personnalisation complète pour les paramètres SMB.

### Permissions du dossier partagé
Le script permet aussi de personnaliser les permissions directement pendant l’installation.

Par exemple :

```bash
Propriétaire du dossier [root] :
Groupe du dossier [root] :
Permissions du dossier (chmod) [0775] :
Permissions des fichiers (chmod) [0664] :
```

Ces valeurs sont appliquées au dossier partagé avec `chown` et `chmod`, puis réutilisées dans `smb.conf` pour les masques de fichiers et de dossiers.

Tu peux aussi conserver les variables d’environnement si besoin :

```bash
SMB_SHARE_NAME="partages"
SMB_SHARE_PATH="/srv/partages"
SMB_GUEST_OK="no"
SMB_READ_ONLY="no"
SMB_DIR_PERMS="0777"
SMB_FILE_PERMS="0666"
```

Pour ajouter un utilisateur Samba sécurisé :

```bash
sudo useradd -m monuser
sudo smbpasswd -a monuser
```

Ensuite, modifiez `/etc/samba/smb.conf` pour adapter les droits et l’authentification selon votre besoin.

## Vérification

Vérifiez que le service est actif :

```bash
sudo systemctl status smbd
sudo testparm -s
smbclient -L localhost
```

Test de connexion à un partage :

```bash
smbclient //localhost/public -U monuser
```

## Exemple d’accès réseau
Sur un client Windows :

```text
\\serveur-ip\public
```

Sur Linux :

```bash
mount -t cifs //serveur-ip/public /mnt/samba -o username=monuser
```

## Documentation
- [Site officiel Samba](https://www.samba.org/)
- [Documentation Samba](https://wiki.samba.org/index.php/Main_Page)

## Notes
- N’utilisez pas le partage public en production sans sécurisation.
- Vérifiez les permissions du dossier de partage avant de l’exposer.
- Adaptez le fichier `/etc/samba/smb.conf` selon votre environnement.
- Mettez régulièrement le système et Samba à jour.
