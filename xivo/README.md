# XiVO — procédure d'installation

## Description

XiVO est une solution libre de téléphonie IP (IPBX) basée sur Asterisk : comptes SIP des utilisateurs, postes téléphoniques, groupes, files d'attente, messagerie vocale, serveur vocal interactif et administration web. Cette procédure installe la version LTS actuelle de XiVO avec le script officiel de l'éditeur, sur une Debian 13 dédiée.

| | |
|---|---|
| **Systèmes** | Debian 13 « Trixie » 64 bits, installation propre et minimale (pour la LTS 2026.05) |
| **Méthode** | Script officiel `xivo_install.sh` (`mirror.xivo.solutions`) |
| **Ports** | 80/443 (interface web), 5060/udp+tcp (SIP), 10000-20000/udp (flux audio RTP) |
| **Script** | `install_xivo.sh` (voir les points d'attention) |

## Prérequis

- Une machine **dédiée** sous Debian 13 minimale, à jour, avec une adresse IP fixe et un nom d'hôte. L'éditeur conseille du matériel physique : Asterisk est sensible aux latences de la virtualisation.
- 4 Go de RAM au minimum.
- Un accès root et une connexion Internet.

## Installation automatique

Sur un Debian 13 propre et **dédié** :

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/xivo
sudo XIVO_CONFIRM=oui XIVO_HOSTNAME=xivo.lab.local bash install_xivo.sh
```

Le script vérifie qu'il s'agit de Debian 13 en 64 bits, met le système à jour (étape 1), télécharge l'installateur officiel `xivo_install.sh` et le lance (étape 2 ; `XIVO_VERSION=2026.05-latest` pour une version précise), puis ouvre les ports si un pare-feu est actif. Sans `XIVO_CONFIRM=oui`, il s'arrête avant toute modification. Il reste l'assistant de configuration (étape 3).

## Installation manuelle


### 1. Préparer la Debian

```bash
apt update && apt full-upgrade -y
apt install -y wget
hostnamectl set-hostname xivo.lab.local
```

### 2. Télécharger et lancer l'installateur officiel

```bash
cd /root
wget http://mirror.xivo.solutions/xivo_install.sh
chmod +x xivo_install.sh
./xivo_install.sh
```

Sans argument, le script installe la version de production actuelle. Pour une version précise :

```bash
./xivo_install.sh -a 2026.05-latest     # LTS 2026.05
./xivo_install.sh -h                    # aide
```

Le script vérifie la version de Debian, ajoute les dépôts XiVO, Docker et PostgreSQL, puis installe l'ensemble des composants (Asterisk, base de données, services XiVO en conteneurs). Compter 15 à 30 minutes.

### 3. Assistant de configuration

Ouvrir `https://<adresse-du-serveur>` (accepter le certificat autosigné). L'assistant demande :

- la langue et le mot de passe du compte `root` de l'interface ;
- le nom d'hôte, le domaine et la configuration réseau ;
- l'entité (nom de l'organisation) et les plages de numéros internes (par exemple `1000` à `1999`).

### 4. Créer des utilisateurs et des lignes

*Services → IPBX → Utilisateurs → Ajouter* : nom, prénom, numéro interne, puis, dans l'onglet *Lignes*, une ligne **SIP**. XiVO génère l'identifiant et le mot de passe SIP à saisir dans le téléphone ou le softphone (Linphone, Zoiper…).

### 5. Ouvrir le pare-feu

Si un pare-feu est actif sur le serveur ou en amont :

```bash
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 5060/udp
ufw allow 5060/tcp
ufw allow 10000:20000/udp
```

## Vérification

```bash
xivo-service status
asterisk -rx "pjsip show endpoints"
```

Enregistrer deux softphones sur deux comptes, puis appeler le numéro interne de l'un depuis l'autre : la sonnerie et le son doivent passer dans les deux sens.

## Dépannage

- **Le téléphone ne s'enregistre pas** : vérifier l'identifiant, le mot de passe SIP et l'accès au port 5060 (`asterisk -rx "pjsip show endpoints"`).
- **Appel établi sans son** : les ports RTP (10000-20000/udp) sont bloqués ou une box fait du NAT entre le téléphone et le serveur.
- Journaux : `/var/log/asterisk/full` et `/var/log/xivo-*`.

## Points d'attention

- `xivo_install.sh` reconfigure entièrement la machine (dépôts, Docker, PostgreSQL) : ne jamais le lancer sur un serveur qui héberge déjà d'autres services.
- La LTS 2026.05 exige Debian 13 « Trixie » ; Ubuntu n'est pas pris en charge par l'éditeur.
- L'installateur est téléchargé en HTTP (adresse donnée par l'éditeur) : le faire depuis un réseau de confiance.
- Ouvrir la plage RTP 10000-20000/udp vers le serveur, sinon les appels n'ont pas de son.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Documentation XiVO](https://documentation.xivo.solutions/)
- [Installation du système XiVO](https://documentation.xivo.solutions/en/2026.05/installation/xivo/installation/installsystem.html)
