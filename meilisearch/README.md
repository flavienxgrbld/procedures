# Meilisearch — procédure d'installation

## Description

Meilisearch est un moteur de recherche rapide et simple à intégrer : il indexe des documents JSON et répond instantanément aux recherches, avec tolérance aux fautes de frappe, filtres et tri. Il s'utilise via une API REST depuis un site ou une application. Cette procédure l'installe à partir du binaire officiel, sous forme de service systemd sécurisé par une clé maîtresse.

| | |
|---|---|
| **Systèmes** | Linux 64 bits avec systemd |
| **Méthode** | Binaire officiel (script `install.meilisearch.com`) |
| **Ports** | 7700/tcp (API) |
| **Script** | `install_meilisearch.sh` |

## Prérequis

- Un accès root et une connexion Internet.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/meilisearch
sudo bash install_meilisearch.sh
```

Lire les points d'attention : le service créé par le script ne trouve pas le binaire.

## Installation manuelle

### 1. Télécharger le binaire

```bash
cd /tmp
curl -L https://install.meilisearch.com | sh
sudo mv ./meilisearch /usr/local/bin/
meilisearch --version
```

### 2. Créer l'utilisateur et les dossiers

```bash
sudo useradd -r -d /var/lib/meilisearch -s /usr/sbin/nologin meilisearch
sudo mkdir -p /var/lib/meilisearch/{data,dumps,snapshots}
sudo chown -R meilisearch:meilisearch /var/lib/meilisearch
```

### 3. Écrire la configuration

`/etc/meilisearch.toml` :

```toml
env = "production"
master_key = "UneCleMaitresseLongueEtAleatoireDe32CaracteresMinimum"
db_path = "/var/lib/meilisearch/data"
dump_dir = "/var/lib/meilisearch/dumps"
snapshot_dir = "/var/lib/meilisearch/snapshots"
http_addr = "0.0.0.0:7700"
```

Générer une clé avec `openssl rand -base64 32`. En mode `production`, la clé maîtresse est obligatoire.

### 4. Créer le service systemd

`/etc/systemd/system/meilisearch.service` :

```ini
[Unit]
Description=Meilisearch
After=network.target

[Service]
Type=simple
User=meilisearch
Group=meilisearch
WorkingDirectory=/var/lib/meilisearch
ExecStart=/usr/local/bin/meilisearch --config-file-path /etc/meilisearch.toml
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```bash
sudo chmod 640 /etc/meilisearch.toml
sudo chown root:meilisearch /etc/meilisearch.toml
sudo systemctl daemon-reload
sudo systemctl enable --now meilisearch
sudo ufw allow 7700/tcp
```

### 5. Récupérer les clés d'API

La clé maîtresse ne sert qu'à obtenir les clés d'usage :

```bash
curl -s http://localhost:7700/keys -H "Authorization: Bearer <master_key>"
```

Utiliser la clé *Default Search API Key* côté site public, et la clé *Default Admin API Key* côté serveur.

### 6. Indexer et chercher

```bash
curl -X POST http://localhost:7700/indexes/films/documents \
  -H "Authorization: Bearer <admin_key>" -H "Content-Type: application/json" \
  --data '[{"id":1,"titre":"Le Fabuleux Destin d Amélie Poulain"},{"id":2,"titre":"Intouchables"}]'

curl "http://localhost:7700/indexes/films/search?q=amelie" -H "Authorization: Bearer <search_key>"
```

## Vérification

```bash
systemctl status meilisearch
curl -s http://localhost:7700/health
```

`/health` doit répondre `{"status":"available"}`.

## Points d'attention

- Le script exécute `install.meilisearch.com`, qui dépose le binaire dans le dossier courant (`/tmp` ou autre), mais son service lance `/usr/bin/meilisearch` : le service ne démarre pas.
- Il démarre Meilisearch sans clé maîtresse et l'expose sur le réseau (port 7700 ouvert) : n'importe qui peut lire, modifier ou supprimer les index.
- Le service tourne sous l'utilisateur partagé `nobody`, déconseillé pour un service qui écrit des données.

## Sources

- [Installer Meilisearch](https://www.meilisearch.com/docs/learn/self_hosted/install_meilisearch_locally)
- [Exécuter Meilisearch en production](https://www.meilisearch.com/docs/guides/deployment/running_production)
