# HashiCorp Nomad — procédure d'installation

## Description

Nomad est un orchestrateur de charges de travail, plus simple que Kubernetes : il planifie et exécute des conteneurs Docker, des binaires ou des machines virtuelles sur un ensemble de serveurs. Cette procédure installe Nomad en mode serveur et client sur une seule machine, pour un labo.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu (dépôt HashiCorp) |
| **Méthode** | Dépôt APT officiel HashiCorp |
| **Ports** | 4646 (HTTP/UI), 4647 (RPC), 4648 (gossip) |
| **Script** | `install_hashicorp_nomad.sh` |

## Prérequis

- Un accès root et une connexion Internet.
- Docker installé pour exécuter des conteneurs (voir la procédure `docker`).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/hashicorp_nomad
sudo bash install_hashicorp_nomad.sh
```

Lire les points d'attention : la configuration écrite par le script empêche Nomad de démarrer.

## Installation manuelle

### 1. Ajouter le dépôt HashiCorp et installer Nomad

```bash
sudo apt update
sudo apt install -y gpg wget
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt install -y nomad
nomad version
```

### 2. Configurer un nœud serveur et client

`/etc/nomad.d/nomad.hcl` :

```hcl
datacenter = "dc1"
data_dir   = "/opt/nomad/data"
bind_addr  = "0.0.0.0"

server {
  enabled          = true
  bootstrap_expect = 1
}

client {
  enabled = true
}

ui {
  enabled = true
}
```

### 3. Démarrer

Le service fourni par le paquet tourne en root : c'est nécessaire pour le client, qui crée les conteneurs.

```bash
sudo systemctl enable --now nomad
sudo ufw allow 4646:4648/tcp
sudo ufw allow 4648/udp
```

### 4. Lancer une première tâche

`web.nomad.hcl` :

```hcl
job "web" {
  datacenters = ["dc1"]

  group "web" {
    network {
      port "http" {
        static = 8080
        to     = 80
      }
    }

    task "nginx" {
      driver = "docker"
      config {
        image = "nginx:alpine"
        ports = ["http"]
      }
    }
  }
}
```

```bash
nomad job run web.nomad.hcl
nomad job status web
curl -I http://localhost:8080
```

## Vérification

```bash
nomad server members
nomad node status
```

L'interface web est accessible sur `http://<adresse-du-serveur>:4646`.

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/nomad.d/nomad.hcl` | Configuration |
| `/opt/nomad/data/` | Données (état, allocations) |

## Dépannage

- Journal : `journalctl -u nomad -f`.
- **Pilote docker non détecté** (`nomad node status -self`) : Docker n'est pas installé ou pas démarré.

## Points d'attention

- La configuration du script ne définit pas `data_dir`, obligatoire : Nomad refuse de démarrer.
- Le service du script tourne sous un utilisateur `nomad` sans privilèges, alors que la partie client a besoin des droits root pour lancer des conteneurs.
- Le script installe Nomad 1.6.0 et a besoin de `unzip`, qu'il n'installe pas. Il n'ouvre que le port 4646.
- Pour un cluster réel : 3 serveurs, des clients séparés, et Consul pour la découverte de services (voir `hashicorp_consul`).

## Sources

- [Installer Nomad](https://developer.hashicorp.com/nomad/docs/install)
- [Démarrer avec Nomad](https://developer.hashicorp.com/nomad/tutorials/get-started)
