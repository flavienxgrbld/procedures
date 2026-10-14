# Pile TIG (Telegraf, InfluxDB, Grafana) — procédure d'installation

## Description

La pile TIG est un ensemble de supervision classique : **Telegraf** collecte les métriques (système, services, SNMP…), **InfluxDB** les stocke dans une base de séries temporelles, et **Grafana** les affiche dans des tableaux de bord. Cette procédure installe les trois outils sur un même serveur et les relie entre eux.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu |
| **Méthode** | Dépôts officiels InfluxData et Grafana |
| **Ports** | 8086/tcp (InfluxDB), 3000/tcp (Grafana) |
| **Script** | `install_tig_stack.sh` |

## Prérequis

- Un accès root et une connexion Internet.
- 2 Go de RAM au minimum.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/tig_stack
sudo bash install_tig_stack.sh
```

Lire les points d'attention : l'ajout des deux dépôts par le script échoue.

## Installation manuelle

### 1. Installer InfluxDB 2 et Telegraf

```bash
sudo apt update
sudo apt install -y curl gnupg
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repos.influxdata.com/influxdata-archive.key | sudo gpg --dearmor -o /etc/apt/keyrings/influxdata-archive.gpg
echo "deb [signed-by=/etc/apt/keyrings/influxdata-archive.gpg] https://repos.influxdata.com/debian stable main" \
  | sudo tee /etc/apt/sources.list.d/influxdata.list
sudo apt update
sudo apt install -y influxdb2 influxdb2-cli telegraf
sudo systemctl enable --now influxdb
```

### 2. Configurer InfluxDB

```bash
influx setup --username admin --password MotDePasseFort --org labo --bucket telegraf --retention 30d --force
influx auth create --org labo --write-buckets --read-buckets --description telegraf
```

Noter le jeton affiché par la seconde commande.

### 3. Relier Telegraf à InfluxDB

Dans `/etc/telegraf/telegraf.conf`, commenter la section `[[outputs.influxdb]]` et ajouter :

```toml
[[outputs.influxdb_v2]]
  urls = ["http://127.0.0.1:8086"]
  token = "<jeton de l'étape 2>"
  organization = "labo"
  bucket = "telegraf"
```

Les entrées `cpu`, `mem`, `disk`, `system` sont activées par défaut.

```bash
sudo systemctl enable --now telegraf
sudo systemctl restart telegraf
```

### 4. Installer Grafana

```bash
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" \
  | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt update
sudo apt install -y grafana
sudo systemctl enable --now grafana-server
sudo ufw allow 3000/tcp
```

### 5. Créer la source de données et un tableau de bord

1. Ouvrir `http://<adresse-du-serveur>:3000` (`admin` / `admin`, puis changer le mot de passe).
2. *Connections → Data sources → InfluxDB* : langage **Flux**, URL `http://localhost:8086`, organisation `labo`, jeton de l'étape 2, bucket `telegraf`.
3. *Dashboards → Import* : importer un tableau de bord communautaire pour Telegraf (par exemple l'identifiant `14126`, « System metrics »), ou en créer un.

## Vérification

```bash
systemctl status influxdb telegraf grafana-server
influx query 'from(bucket:"telegraf") |> range(start:-5m) |> limit(n:3)'
```

## Points d'attention

- Pour InfluxDB, le script déclare le dépôt avec un fichier de clé (`signed-by=/usr/share/keyrings/influxdb-archive-keyring.gpg`) qu'il ne crée jamais : `apt update` refuse le dépôt.
- Pour Grafana, il récupère une clé sur un serveur de clés avec `apt-key` et utilise l'ancien dépôt `packages.grafana.com`, remplacé par `apt.grafana.com`. `apt-key` est retiré des distributions récentes.
- Il ne configure pas Telegraf : la sortie par défaut vise InfluxDB 1.x (base `telegraf` sans jeton), refusée par InfluxDB 2. Aucune métrique n'est enregistrée tant que l'étape 3 n'est pas faite.

## Sources

- [Installer Telegraf](https://docs.influxdata.com/telegraf/v1/install/)
- [Installer InfluxDB 2](https://docs.influxdata.com/influxdb/v2/install/)
- [Installer Grafana sur Debian/Ubuntu](https://grafana.com/docs/grafana/latest/setup-grafana/installation/debian/)
