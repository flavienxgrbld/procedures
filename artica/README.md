# Artica — procédure d'installation

## Description

Artica est une solution de proxy, de filtrage web et de sécurité réseau administrable depuis une interface web (proxy Squid, filtrage, DNS, pare-feu, statistiques). Cette procédure prépare un serveur Debian, ajoute le dépôt Artica et installe le paquet.

| | |
|---|---|
| **Systèmes** | Debian (recommandé par l'éditeur) ; essais sur RHEL/openSUSE |
| **Méthode** | Dépôt de paquets Artica |
| **Ports** | 80 et 443 (interface), 3128 (proxy), 8080 et 8443 (consoles) |
| **Script** | `install_artica.sh` |

## Prérequis

- Une machine dédiée (physique ou VM) sous Debian, avec 4 Go de RAM et 2 cœurs au minimum.
- Un accès root et une connexion Internet.
- Une adresse IP fixe : les postes clients seront configurés pour passer par ce proxy.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/artica
sudo bash install_artica.sh
```

Les ports et l'URL du dépôt peuvent être ajustés par variables d'environnement :

```bash
sudo ARTICA_HTTP_PORT=80 ARTICA_PROXY_PORT=3128 ARTICA_REPO_URL=https://download.artica.fr/ bash install_artica.sh
```

| Variable | Valeur par défaut |
|---|---|
| `ARTICA_REPO_URL` | `https://download.artica.fr/` |
| `ARTICA_PACKAGE` | `artica` |
| `ARTICA_SERVICE` | `artica` |
| `ARTICA_HTTP_PORT` / `ARTICA_HTTPS_PORT` | `80` / `443` |
| `ARTICA_PROXY_PORT` | `3128` |

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
systemctl status artica
ss -tlnp | grep -E ':(80|443|3128)\b'
curl -x http://<adresse-du-serveur>:3128 -I https://www.debian.org
```

## Dépannage

- Le nom exact du service dépend de la version : le rechercher avec `systemctl list-unit-files | grep -i artica`.
- Journal du script : `/var/log/install_script.log`.

## Points d'attention

- Le dépôt utilisé par défaut (`https://download.artica.fr/`) ne répond pas (vérifié le 13/10/2026). Le script ne peut donc pas installer Artica tel quel : il prépare le système, puis signale que le paquet est introuvable. Utiliser l'ISO officielle, ou indiquer un dépôt valide avec `ARTICA_REPO_URL`.
- Sur une distribution sans paquets gérés (`pacman` ou autre), le script appelle la fonction `fatal`, qui n'existe pas dans la bibliothèque commune : il s'arrête avec une erreur « command not found ».

## Sources

- [Site officiel Artica](https://artica-proxy.com/)
- [Documentation Artica](https://wiki.articatech.com/)
