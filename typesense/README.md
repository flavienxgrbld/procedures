# Typesense — procédure d'installation

## Description

Typesense est un moteur de recherche libre et très rapide, tolérant aux fautes de frappe, avec filtres, facettes, tri et recherche vectorielle. Il s'utilise via une API REST, depuis un site ou une application. Cette procédure installe le serveur avec le paquet officiel `.deb`, qui génère sa propre clé d'API.

| | |
|---|---|
| **Systèmes** | Ubuntu 20.04+ et Debian récents (64 bits) |
| **Méthode** | Paquet officiel `.deb` (`dl.typesense.org`), version 30.2 |
| **Ports** | 8108/tcp (API) |
| **Script** | `install_typesense.sh` |

## Prérequis

- Un accès root et une connexion Internet.
- De la RAM à hauteur de l'index (Typesense garde l'index en mémoire).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/typesense
sudo bash install_typesense.sh
```

Lire les points d'attention : l'archive téléchargée par le script n'existe plus.

## Installation manuelle

### 1. Installer le paquet

```bash
cd /tmp
wget https://dl.typesense.org/releases/30.2/typesense-server-30.2-amd64.deb
sudo apt install -y ./typesense-server-30.2-amd64.deb
```

Le service `typesense-server` est créé et démarré.

### 2. Récupérer la clé d'administration

```bash
sudo grep api-key /etc/typesense/typesense-server.ini
```

Cette clé donne tous les droits : la garder côté serveur uniquement.

### 3. Ouvrir le port aux applications

```bash
sudo ufw allow from 192.168.1.0/24 to any port 8108 proto tcp
```

### 4. Créer une collection et indexer

```bash
export TS_KEY=<clé d'administration>

curl -X POST http://localhost:8108/collections -H "X-TYPESENSE-API-KEY: $TS_KEY" \
  -d '{"name":"films","fields":[{"name":"titre","type":"string"},{"name":"annee","type":"int32"}],"default_sorting_field":"annee"}'

curl -X POST "http://localhost:8108/collections/films/documents/import?action=create" \
  -H "X-TYPESENSE-API-KEY: $TS_KEY" \
  --data-binary $'{"titre":"Intouchables","annee":2011}\n{"titre":"Amélie","annee":2001}'

curl "http://localhost:8108/collections/films/documents/search?q=amelei&query_by=titre" \
  -H "X-TYPESENSE-API-KEY: $TS_KEY"
```

La recherche `amelei` (avec une faute) trouve « Amélie ».

### 5. Créer une clé de recherche pour le site public

```bash
curl -X POST http://localhost:8108/keys -H "X-TYPESENSE-API-KEY: $TS_KEY" \
  -d '{"description":"recherche","actions":["documents:search"],"collections":["films"]}'
```

## Vérification

```bash
systemctl status typesense-server
curl -s http://localhost:8108/health
```

`/health` doit répondre `{"ok":true}`.

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/typesense/typesense-server.ini` | Configuration (clé d'API, port, dossier de données) |
| `/var/lib/typesense/` | Données |
| `/var/log/typesense/` | Journaux |

## Points d'attention

- Le script télécharge `typesense-server-0.25.0-linux-amd64.tar.gz`, qui n'existe plus (erreur 404, vérifié le 13/10/2026) : il s'arrête au téléchargement. La version actuelle est la 30.2.
- Son service fixe la clé d'API `xyz`, la valeur d'exemple de la documentation, et le port 8108 est ouvert à tout le réseau : n'importe qui peut lire, modifier ou supprimer les données.

## Sources

- [Installer Typesense](https://typesense.org/docs/guide/install-typesense.html)
- [Documentation de l'API](https://typesense.org/docs/)
