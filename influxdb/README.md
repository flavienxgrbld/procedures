# InfluxDB — procédure d'installation

## Description

InfluxDB est une base de données de séries temporelles, optimisée pour stocker et interroger des mesures horodatées : métriques de serveurs, capteurs, IoT. Elle s'associe souvent à Telegraf (collecte) et Grafana (tableaux de bord). Cette procédure installe InfluxDB 2 depuis le dépôt officiel d'InfluxData.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu, RHEL/Fedora |
| **Méthode** | Dépôt officiel `repos.influxdata.com` |
| **Ports** | 8086/tcp (API et interface web) |
| **Script** | `install_influxdb.sh` |

## Prérequis

- Un accès root et une connexion Internet.
- Un disque rapide si le volume de données est important.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/influxdb
sudo bash install_influxdb.sh
```

Lire les points d'attention : l'ajout du dépôt par le script échoue sur Debian et Ubuntu.

## Installation manuelle

### 1. Ajouter le dépôt InfluxData

```bash
sudo apt update
sudo apt install -y curl gnupg
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repos.influxdata.com/influxdata-archive.key | sudo gpg --dearmor -o /etc/apt/keyrings/influxdata-archive.gpg
echo "deb [signed-by=/etc/apt/keyrings/influxdata-archive.gpg] https://repos.influxdata.com/debian stable main" \
  | sudo tee /etc/apt/sources.list.d/influxdata.list
sudo apt update
```

### 2. Installer InfluxDB et son client

```bash
sudo apt install -y influxdb2 influxdb2-cli
sudo systemctl enable --now influxdb
sudo ufw allow 8086/tcp
```

### 3. Configuration initiale

Dans le navigateur, sur `http://<adresse-du-serveur>:8086`, ou en ligne de commande :

```bash
influx setup \
  --username admin \
  --password MotDePasseFort \
  --org labo \
  --bucket metriques \
  --retention 30d \
  --force
```

Cette commande crée l'utilisateur, l'organisation, un premier *bucket* (conservation 30 jours) et un jeton d'administration enregistré dans la configuration du client `influx`.

### 4. Créer un jeton pour les applications

```bash
influx auth create --org labo --write-buckets --read-buckets --description "telegraf"
```

Utiliser ce jeton dans Telegraf ou Grafana, plutôt que le jeton d'administration.

## Vérification

```bash
systemctl status influxdb
curl -s http://localhost:8086/health
influx bucket list
```

`/health` doit renvoyer `"status": "pass"`.

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/influxdb/config.toml` | Configuration du serveur |
| `/var/lib/influxdb/` | Données |
| `~/.influxdbv2/configs` | Configuration et jeton du client `influx` |

## Dépannage

- Journal : `journalctl -u influxdb -f`.
- Sauvegarde : `influx backup /srv/sauvegardes/influx-$(date +%F)`.

## Points d'attention

- Le script déclare le dépôt avec `signed-by=/usr/share/keyrings/influxdb-archive-keyring.gpg`, mais ne crée jamais ce fichier : il ajoute la clé avec `apt-key`. `apt update` refuse alors le dépôt, et le paquet `influxdb2` reste introuvable.
- `apt-key` est retiré des versions récentes de Debian et Ubuntu.
- Le script n'installe pas le client `influx` (`influxdb2-cli`), et ne fait pas la configuration initiale : n'importe qui ouvrant le port 8086 peut créer le premier compte administrateur. Faire l'étape 3 immédiatement.

## Sources

- [Installer InfluxDB 2](https://docs.influxdata.com/influxdb/v2/install/)
- [Configuration initiale](https://docs.influxdata.com/influxdb/v2/get-started/setup/)
