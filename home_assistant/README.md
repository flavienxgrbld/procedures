# Home Assistant — procédure d'installation

## Description

Home Assistant est une plateforme domotique libre qui centralise et automatise les objets connectés de la maison (éclairage, chauffage, capteurs, caméras), localement, sans dépendre d'un service en ligne. Cette procédure l'installe en conteneur Docker, l'une des méthodes officiellement prises en charge.

| | |
|---|---|
| **Systèmes** | Toute distribution avec Docker |
| **Méthode** | Image officielle `ghcr.io/home-assistant/home-assistant` |
| **Dossier** | `/opt/homeassistant` |
| **Ports** | 8123/tcp |
| **Script** | `install_home_assistant.sh` |

## Prérequis

- Docker installé (voir la procédure `docker`).
- 2 Go de RAM au minimum.
- Pour une installation dédiée avec gestion des modules complémentaires (*add-ons*), préférer **Home Assistant OS** en machine virtuelle (image disponible pour Proxmox, VirtualBox, VMware).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/home_assistant
sudo bash install_home_assistant.sh
```

Lire les points d'attention : la méthode du script ne fonctionne plus sur les distributions récentes.

## Installation manuelle (conteneur)

### 1. Créer le dossier de configuration

```bash
sudo mkdir -p /opt/homeassistant/config
cd /opt/homeassistant
```

### 2. Décrire le service

`/opt/homeassistant/compose.yaml` :

```yaml
services:
  homeassistant:
    image: ghcr.io/home-assistant/home-assistant:stable
    container_name: homeassistant
    restart: unless-stopped
    privileged: true
    network_mode: host
    environment:
      TZ: Europe/Paris
    volumes:
      - ./config:/config
      - /etc/localtime:/etc/localtime:ro
      - /run/dbus:/run/dbus:ro
```

Le mode réseau `host` permet à Home Assistant de découvrir les appareils du réseau local (mDNS, UPnP).

### 3. Démarrer

```bash
sudo docker compose up -d
sudo ufw allow 8123/tcp
```

### 4. Assistant de démarrage

Ouvrir `http://<adresse-du-serveur>:8123` (une à deux minutes après le premier démarrage), créer le compte propriétaire, indiquer la localisation et le fuseau horaire, puis ajouter les appareils détectés.

## Vérification

```bash
sudo docker compose ps
sudo docker compose logs -f homeassistant
```

## Mise à jour

```bash
cd /opt/homeassistant
sudo docker compose pull
sudo docker compose up -d
```

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/opt/homeassistant/config/configuration.yaml` | Configuration principale |
| `/opt/homeassistant/config/` | Automatisations, base de données, sauvegardes |

## Dépannage

- Appareils non découverts : vérifier `network_mode: host` et que le serveur est sur le même réseau que les appareils.
- Clé USB Zigbee/Z-Wave : la passer au conteneur avec `devices: ["/dev/ttyUSB0:/dev/ttyUSB0"]`.

## Points d'attention

- Le script installe Home Assistant avec `pip3 install homeassistant` dans le Python du système. Sur Debian 12 et Ubuntu 23.04 et plus récents, cette commande est refusée (« externally-managed-environment »). De plus, Home Assistant exige une version très récente de Python, rarement celle de la distribution.
- Le service du script tourne en `root`, ce que la documentation déconseille.
- La méthode *Core* (installation Python manuelle) n'est plus prise en charge par le projet : les méthodes conseillées sont Home Assistant OS et le conteneur.

## Sources

- [Installer Home Assistant sur Linux](https://www.home-assistant.io/installation/linux)
- [Documentation Home Assistant](https://www.home-assistant.io/docs/)
