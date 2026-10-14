# Uptime Kuma — procédure d'installation

## Description

Uptime Kuma est un outil de surveillance de disponibilité simple et agréable : il vérifie à intervalles réguliers des sites web, des ports, des pings, des enregistrements DNS ou des conteneurs, conserve l'historique, envoie des alertes (e-mail, Telegram, Discord…) et publie des pages de statut. Cette procédure l'installe avec Docker.

| | |
|---|---|
| **Systèmes** | Toute distribution avec Docker |
| **Méthode** | Image officielle `louislam/uptime-kuma` |
| **Dossier** | `/opt/uptime-kuma` |
| **Ports** | 3001/tcp |
| **Script** | `install_uptime_kuma.sh` |

## Prérequis

- Docker installé (procédure `docker`).
- Un accès root.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/uptime_kuma
sudo bash install_uptime_kuma.sh
```

Le script démarre le conteneur `uptime-kuma` avec ses données dans `/opt/uptime-kuma/data`.

## Installation manuelle

### 1. Décrire le service

```bash
sudo mkdir -p /opt/uptime-kuma
cd /opt/uptime-kuma
```

`/opt/uptime-kuma/compose.yaml` :

```yaml
services:
  uptime-kuma:
    image: louislam/uptime-kuma:2
    container_name: uptime-kuma
    restart: unless-stopped
    ports:
      - "3001:3001"
    volumes:
      - ./data:/app/data
```

### 2. Démarrer

```bash
sudo docker compose up -d
sudo ufw allow 3001/tcp
```

### 3. Configurer

1. Ouvrir `http://<adresse-du-serveur>:3001` et créer le compte administrateur.
2. **Ajouter une sonde** : type HTTP(s), TCP, Ping, DNS…, nom, adresse et intervalle.
3. *Paramètres → Notifications* : configurer un canal d'alerte, puis l'associer aux sondes.
4. *Pages de statut* : créer une page publique qui affiche l'état des services.

## Vérification

```bash
sudo docker compose ps
sudo docker compose logs -f uptime-kuma
```

## Mise à jour

```bash
cd /opt/uptime-kuma
sudo docker compose pull
sudo docker compose up -d
```

Sauvegarder le dossier `data/` avant une mise à jour majeure.

## Points d'attention

- Le script installe le paquet `docker.io` sans vérifier si Docker est déjà installé depuis le dépôt officiel : les deux installations entrent en conflit. Utiliser la procédure `docker`.
- Il crée un utilisateur système `uptimekuma` qui ne sert à rien, le conteneur tournant de façon indépendante.
- Il utilise l'étiquette `latest` : préférer une version majeure (`:2`) pour éviter une mise à jour majeure non prévue.
- Ne pas stocker `data/` sur un partage NFS : la base SQLite risque d'être corrompue.

## Sources

- [Installer Uptime Kuma](https://github.com/louislam/uptime-kuma/wiki/%F0%9F%94%A7-How-to-Install)
- [Dépôt Uptime Kuma](https://github.com/louislam/uptime-kuma)
