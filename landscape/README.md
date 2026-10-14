# Landscape — procédure d'installation

## Description

Landscape est l'outil de Canonical pour administrer un parc de machines Ubuntu depuis une console web : inventaire, mises à jour de paquets en masse, exécution de scripts à distance, alertes et surveillance. Cette procédure installe un serveur Landscape auto-hébergé en mode *quickstart* (tous les composants sur une seule machine).

| | |
|---|---|
| **Systèmes** | Ubuntu Server 24.04 LTS uniquement |
| **Méthode** | PPA `landscape/self-hosted-24.04`, paquet `landscape-server-quickstart` |
| **Ports** | 80/tcp et 443/tcp |
| **Script** | `install_landscape.sh` |

## Prérequis

- Une machine **Ubuntu Server 24.04** dédiée, avec 4 Go de RAM et 2 cœurs au minimum.
- Un nom d'hôte pleinement qualifié (FQDN), résolu par le DNS (ici `landscape.exemple.local`).
- Un compte Ubuntu One. Landscape est gratuit jusqu'à un nombre limité de machines, au-delà il faut un abonnement Ubuntu Pro.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/landscape
sudo bash install_landscape.sh
```

Lire les points d'attention : le dépôt utilisé par le script n'existe plus.

## Installation manuelle

### 1. Régler le nom d'hôte

```bash
sudo hostnamectl set-hostname landscape.exemple.local
hostname -f
```

### 2. Ajouter le PPA et installer

```bash
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:landscape/self-hosted-24.04
sudo apt update
sudo apt install -y landscape-server-quickstart
```

Le paquet installe et configure PostgreSQL, RabbitMQ, Apache et les services Landscape. L'opération prend plusieurs minutes.

### 3. Ouvrir le pare-feu

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### 4. Créer le compte administrateur

Ouvrir `https://landscape.exemple.local` (accepter le certificat autosigné), puis créer le premier compte administrateur.

### 5. Inscrire une machine

Sur chaque machine Ubuntu à gérer :

```bash
sudo apt install -y landscape-client
sudo landscape-config --computer-title "$(hostname)" --account-name standalone \
  --url https://landscape.exemple.local/message-system \
  --ping-url http://landscape.exemple.local/ping
```

Accepter ensuite la machine dans la console (*Computers → Pending computers*).

## Vérification

```bash
sudo lsctl status
```

La console affiche les machines inscrites et leurs mises à jour en attente.

## Dépannage

- Journaux : `/var/log/landscape-server/`.
- Le client ne s'inscrit pas : vérifier que le nom du serveur est résolu depuis le client et que le certificat est accepté (option `--ssl-public-key` de `landscape-config`).

## Points d'attention

- Le script ajoute le PPA `landscape/self-hosted-16.04`, qui n'existe plus (vérifié le 13/10/2026) : le paquet `landscape-server` est introuvable.
- Le script accepte toute distribution utilisant apt, y compris Debian, alors que Landscape Server ne fonctionne que sur Ubuntu.
- Il démarre un service `landscape-server`, alors que l'installation *quickstart* gère plusieurs services, pilotés avec `lsctl`.

## Sources

- [Installation rapide (quickstart)](https://ubuntu.com/landscape/docs/quickstart-deployment)
- [PPA Landscape 24.04](https://launchpad.net/~landscape/+archive/ubuntu/self-hosted-24.04)
