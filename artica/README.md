# Artica — procédure d'installation

## Description

Artica est une solution de proxy, de filtrage web et de sécurité réseau administrable depuis une interface web (proxy Squid, filtrage, DNS, pare-feu, statistiques). Artica s'installe soit depuis l'image ISO officielle (méthode recommandée), soit sur un Debian déjà installé avec l'installateur officiel de l'éditeur, que lance le script.

| | |
|---|---|
| **Systèmes** | Debian amd64 uniquement (ISO actuelle : Artica 4.50 sur Debian 12) |
| **Méthode** | Image ISO officielle, ou installateur officiel `install-manuall.sh` sur Debian |
| **Ports** | 9000/tcp (interface d'administration HTTPS), 3128/tcp (proxy) |
| **Script** | `install_artica.sh` |

## Prérequis

- Une machine dédiée (physique ou VM) sous Debian, avec 4 Go de RAM et 2 cœurs au minimum.
- Un accès root et une connexion Internet.
- Une adresse IP fixe : les postes clients seront configurés pour passer par ce proxy.

## Installation automatique

> ⚠️ Artica transforme tout le système (environ 630 paquets) et **ne se désinstalle pas**. L'éditeur déconseille de l'installer sur un serveur déjà en production : utiliser une VM dédiée.

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/artica
sudo ARTICA_CONFIRM=oui bash install_artica.sh
sudo reboot
```

Le script vérifie qu'il s'agit d'un Debian 64 bits, télécharge l'installateur officiel indiqué par le wiki Artica (`http://articatech.net/download/v4/install-manuall.sh`) et le lance. L'installateur pose une question sur le mode : répondre **No** pour l'installation complète (proxy, messagerie, DNS prêts à l'emploi), **Yes** pour un système minimal. Sans `ARTICA_CONFIRM=oui`, le script s'arrête avant toute modification.

Une autre URL d'installateur peut être indiquée avec `ARTICA_INSTALLER_URL`.

## Installation manuelle (image ISO officielle, recommandée)

L'éditeur distribue Artica sous forme d'image ISO prête à l'emploi, basée sur Debian : c'est la méthode la plus fiable, en particulier en machine virtuelle (Proxmox, VirtualBox, VMware).

### 1. Télécharger l'ISO

Depuis le site officiel (rubrique *Download*), récupérer la dernière image ISO d'Artica.

### 2. Créer la machine virtuelle

- 4 Go de RAM et 2 vCPU au minimum, disque de 50 Go ou plus.
- Une carte réseau sur le réseau des postes à filtrer.
- Démarrer sur l'ISO et suivre l'installation (partitionnement automatique, puis redémarrage).

### 3. Configurer le réseau

Au premier démarrage, le menu console d'Artica permet de définir l'adresse IP fixe, la passerelle et les DNS du serveur.

### 4. Première connexion à l'interface

Ouvrir `https://<adresse-du-serveur>:9000` ou l'URL affichée par la console, puis suivre l'assistant : nom du serveur, compte administrateur, activation du proxy.

### 5. Configurer les postes clients

Sur les postes, définir le proxy `<adresse-du-serveur>:3128` (paramètres réseau, GPO ou fichier PAC).

## Vérification

```bash
systemctl list-units --type=service | grep -iE 'artica|squid'
ss -tlnp | grep -E ':(9000|3128)\b'
curl -x http://<adresse-du-serveur>:3128 -I https://www.debian.org
```

## Dépannage

- Le nom exact du service dépend de la version : le rechercher avec `systemctl list-unit-files | grep -i artica`.
- Journal du script : `/var/log/install_script.log`.

## Points d'attention

- L'installateur sur Debian existant est décrit par le wiki Artica pour la version 4.30 LTS, sur Debian 10. Pour Artica 4.50 (Debian 12), l'éditeur met en avant les images ISO : c'est la méthode à privilégier.
- L'installateur est téléchargé en HTTP (adresse donnée par l'éditeur) : il n'est pas authentifié. Sur un réseau non maîtrisé, préférer l'ISO.
- Artica ne s'installe ni sur RHEL/openSUSE ni sur processeur ARM ; l'ancien dépôt `download.artica.fr` utilisé par la version précédente du script n'existe pas.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Site officiel Artica](https://artica-proxy.com/)
- [Documentation Artica](https://wiki.articatech.com/)
- [Wiki Artica — installation sur un Debian déjà installé](https://wiki.articatech.com/getting-started/install-manual)
