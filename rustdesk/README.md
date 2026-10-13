# RustDesk Server — procédure d'installation

## Description

RustDesk est un logiciel libre de prise en main à distance, alternative à TeamViewer ou AnyDesk. Auto-hébergé, son serveur assure la mise en relation des postes (**hbbs**) et le relais du trafic quand une connexion directe est impossible (**hbbr**), sans passer par les serveurs publics. Cette procédure installe le serveur avec Docker Compose et configure les clients.

| | |
|---|---|
| **Systèmes** | Toute distribution avec Docker |
| **Méthode** | Image officielle `rustdesk/rustdesk-server` (services hbbs et hbbr) |
| **Dossier** | `/opt/rustdesk` |
| **Ports** | 21115-21117/tcp, 21116/udp (21118-21119/tcp pour le client web, optionnel) |
| **Script** | `install_rustdesk.sh` |

## Prérequis

- Docker et Docker Compose (procédure `docker`).
- Une adresse IP fixe ou un nom de domaine (ici `rustdesk.exemple.fr`), avec les ports ouverts depuis Internet si des postes extérieurs doivent se connecter.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/rustdesk
sudo bash install_rustdesk.sh
```

Lire les points d'attention : le conteneur créé par le script ne lance aucun des deux services.

## Installation manuelle

### 1. Décrire les services

```bash
sudo mkdir -p /opt/rustdesk
cd /opt/rustdesk
```

`/opt/rustdesk/compose.yaml` :

```yaml
services:
  hbbs:
    container_name: hbbs
    image: rustdesk/rustdesk-server:latest
    command: hbbs -r rustdesk.exemple.fr:21117
    ports:
      - "21115:21115"
      - "21116:21116"
      - "21116:21116/udp"
    volumes:
      - ./data:/root
    depends_on: [hbbr]
    restart: unless-stopped

  hbbr:
    container_name: hbbr
    image: rustdesk/rustdesk-server:latest
    command: hbbr
    ports:
      - "21117:21117"
    volumes:
      - ./data:/root
    restart: unless-stopped
```

### 2. Démarrer et ouvrir les ports

```bash
sudo docker compose up -d
sudo ufw allow 21115:21117/tcp
sudo ufw allow 21116/udp
```

### 3. Récupérer la clé publique

Au premier démarrage, le serveur génère une paire de clés :

```bash
sudo cat /opt/rustdesk/data/id_ed25519.pub
```

### 4. Configurer les clients

Dans RustDesk sur chaque poste : *Paramètres → Réseau → Serveur ID/Relais* :

- **Serveur ID** : `rustdesk.exemple.fr`
- **Clé** : le contenu de `id_ed25519.pub`

Avec la clé renseignée, le serveur refuse les clients qui ne la connaissent pas, et les connexions sont chiffrées.

## Vérification

```bash
sudo docker compose ps
sudo docker compose logs hbbs
```

Sur un client configuré, l'état « Prêt » s'affiche en bas de la fenêtre ; une connexion vers un autre poste du même serveur doit aboutir.

## Points d'attention

- Le script lance un seul conteneur `rustdesk/rustdesk-server` sans commande. Cette image doit être démarrée avec `hbbs` ou `hbbr` : sans commande, aucun service n'écoute.
- Il publie et ouvre le port 8000, qui n'est pas utilisé par RustDesk.
- Ne jamais diffuser le fichier privé `id_ed25519` : seul `id_ed25519.pub` se partage avec les clients.

## Sources

- [Installer le serveur RustDesk avec Docker](https://rustdesk.com/docs/en/self-host/rustdesk-server-oss/docker/)
- [Dépôt rustdesk-server](https://github.com/rustdesk/rustdesk-server)
