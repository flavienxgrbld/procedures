# HashiCorp Consul — procédure d'installation

## Description

Consul est un outil de découverte de services et de configuration distribuée : les services s'y enregistrent, Consul vérifie leur santé et permet de les trouver par DNS ou par API. Il offre aussi un stockage clé/valeur et un maillage de services (service mesh). Cette procédure installe un serveur Consul autonome pour un labo, avec l'interface web.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu (dépôt HashiCorp) ; binaire pour les autres distributions |
| **Méthode** | Dépôt APT officiel HashiCorp |
| **Ports** | 8500 (HTTP/UI), 8600 (DNS), 8300-8302 (communication du cluster) |
| **Script** | `install_hashicorp_consul.sh` |

## Prérequis

- Un accès root et une adresse IP fixe (ici `192.168.1.30`).
- Pour un vrai cluster de production : 3 ou 5 serveurs.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/hashicorp_consul
sudo bash install_hashicorp_consul.sh
```

Lire les points d'attention : la configuration écrite par le script empêche Consul de démarrer.

## Installation manuelle

### 1. Ajouter le dépôt HashiCorp et installer Consul

```bash
sudo apt update
sudo apt install -y gpg wget
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt install -y consul
consul version
```

Le paquet crée l'utilisateur `consul`, le dossier `/opt/consul` et le service systemd.

### 2. Configurer un serveur unique

`/etc/consul.d/consul.hcl` :

```hcl
datacenter       = "dc1"
data_dir         = "/opt/consul"
server           = true
bootstrap_expect = 1
ui_config {
  enabled = true
}
bind_addr   = "192.168.1.30"
client_addr = "0.0.0.0"
```

Pour sécuriser les échanges, générer une clé de chiffrement avec `consul keygen` et l'ajouter : `encrypt = "<clé>"`.

### 3. Vérifier puis démarrer

```bash
sudo consul validate /etc/consul.d/
sudo systemctl enable --now consul
```

### 4. Ouvrir les ports

```bash
sudo ufw allow 8500/tcp
sudo ufw allow 8600/udp
sudo ufw allow 8300:8302/tcp
sudo ufw allow 8301:8302/udp
```

### 5. Enregistrer un service

`/etc/consul.d/web.hcl` :

```hcl
service {
  name = "web"
  port = 80
  check {
    http     = "http://localhost:80"
    interval = "10s"
  }
}
```

```bash
sudo consul reload
```

## Vérification

```bash
consul members
consul catalog services
dig @127.0.0.1 -p 8600 web.service.consul
```

L'interface web est accessible sur `http://<adresse-du-serveur>:8500/ui`.

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/consul.d/` | Configuration et définitions de services |
| `/opt/consul/` | Données (état Raft, catalogue) |

## Dépannage

- Journal : `journalctl -u consul -f`.
- **« No cluster leader »** : `bootstrap_expect` est supérieur au nombre de serveurs réellement démarrés.

## Points d'attention

- La configuration du script ne définit pas `data_dir`, obligatoire pour un serveur Consul : le service refuse de démarrer.
- Elle indique `bootstrap_expect = 3` sur une seule machine : même avec `data_dir`, aucun leader n'est jamais élu et Consul reste inutilisable.
- `bind_addr = "0.0.0.0"` échoue si la machine a plusieurs adresses privées : indiquer l'adresse précise.
- Le script installe Consul 1.16.0 et a besoin de `unzip`, qu'il n'installe pas. Le dépôt HashiCorp (étape 1) fournit la version à jour.

## Sources

- [Installer Consul](https://developer.hashicorp.com/consul/docs/install)
- [Référence de la configuration de l'agent](https://developer.hashicorp.com/consul/docs/agent/config)
