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

Le script installe InfluxDB 2, Telegraf et Grafana depuis les dépôts officiels (clés dans `/etc/apt/keyrings`), fait la configuration initiale d'InfluxDB (étape 2), crée un jeton en écriture pour Telegraf et un jeton en lecture pour Grafana, relie Telegraf à InfluxDB 2 (étape 3) et déclare la source de données InfluxDB dans Grafana (provisioning) : les métriques du serveur sont visibles dès la fin du script. Identifiants : `/root/tig_identifiants.txt`.

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

- Changer le mot de passe `admin` / `admin` de Grafana dès la première connexion (Grafana l'impose).
- Les jetons créés par le script sont limités au bucket `telegraf` (écriture pour Telegraf, lecture pour Grafana) : garder le jeton d'administration pour l'administration seulement.
- Ouvrir les ports 3000 et 8086 au réseau d'administration uniquement.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Installer Telegraf](https://docs.influxdata.com/telegraf/v1/install/)
- [Installer InfluxDB 2](https://docs.influxdata.com/influxdb/v2/install/)
- [Installer Grafana sur Debian/Ubuntu](https://grafana.com/docs/grafana/latest/setup-grafana/installation/debian/)
