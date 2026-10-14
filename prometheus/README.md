# Prometheus — procédure d'installation

## Description

Prometheus est un système de supervision qui collecte à intervalles réguliers des métriques (CPU, mémoire, disque, services…) exposées par des « exporteurs », les stocke dans une base de séries temporelles et déclenche des alertes. Il s'associe à Grafana pour les tableaux de bord et à Alertmanager pour les notifications. Cette procédure installe Prometheus et l'exporteur système `node_exporter`.

| | |
|---|---|
| **Systèmes** | Linux 64 bits avec systemd |
| **Méthode** | Binaire officiel (GitHub), dernière version |
| **Ports** | 9090/tcp (Prometheus), 9100/tcp (node_exporter) |
| **Script** | `install_prometheus.sh` |

## Prérequis

- Un accès root et une connexion Internet.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/prometheus
sudo bash install_prometheus.sh
```

Le script télécharge la dernière version de Prometheus, crée l'utilisateur, la configuration et le service. Ajouter ensuite les cibles à superviser (étape 5).

## Installation manuelle

### 1. Créer l'utilisateur et les dossiers

```bash
sudo useradd -r -s /bin/false prometheus
sudo mkdir -p /etc/prometheus /var/lib/prometheus
```

### 2. Installer Prometheus

Prendre la dernière version sur la page des versions (ici la 3.15.0) :

```bash
cd /tmp
VER=3.15.0
wget https://github.com/prometheus/prometheus/releases/download/v${VER}/prometheus-${VER}.linux-amd64.tar.gz
tar -xzf prometheus-${VER}.linux-amd64.tar.gz
sudo cp prometheus-${VER}.linux-amd64/{prometheus,promtool} /usr/local/bin/
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
```

### 3. Écrire la configuration

`/etc/prometheus/prometheus.yml` :

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: serveurs
    static_configs:
      - targets: ["localhost:9100", "192.168.1.21:9100", "192.168.1.22:9100"]
```

```bash
promtool check config /etc/prometheus/prometheus.yml
```

### 4. Créer le service systemd

`/etc/systemd/system/prometheus.service` :

```ini
[Unit]
Description=Prometheus
After=network-online.target

[Service]
User=prometheus
Group=prometheus
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --storage.tsdb.retention.time=30d
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now prometheus
sudo ufw allow from 192.168.1.0/24 to any port 9090 proto tcp
```

### 5. Installer node_exporter sur chaque machine à superviser

Sur Debian/Ubuntu, le paquet de la distribution suffit :

```bash
sudo apt install -y prometheus-node-exporter
sudo systemctl enable --now prometheus-node-exporter
sudo ufw allow from <adresse-de-prometheus> to any port 9100 proto tcp
```

## Vérification

```bash
systemctl status prometheus
curl -s http://localhost:9090/-/healthy
```

Dans l'interface `http://<adresse-du-serveur>:9090`, *Status → Targets* doit afficher toutes les cibles à l'état **UP**. Tester une requête dans l'explorateur : `100 - (avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)` (taux d'utilisation du CPU).

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/prometheus/prometheus.yml` | Configuration (cibles, règles) |
| `/var/lib/prometheus/` | Base de séries temporelles |

## Dépannage

- Recharger la configuration sans redémarrer : `sudo systemctl reload prometheus`.
- Cible **DOWN** : l'exporteur n'est pas démarré, ou un pare-feu bloque le port 9100.

## Points d'attention

- Le script place la configuration dans `/opt/prometheus` au lieu de l'emplacement habituel `/etc/prometheus`, et ne supervise que Prometheus lui-même : aucun exporteur n'est installé.
- Il ouvre le port 9090 à tout le réseau, alors que l'interface de Prometheus n'a pas d'authentification.
- Pour les alertes, voir la procédure `alertmanager` ; pour les tableaux de bord, la procédure `tig_stack` (Grafana).

## Sources

- [Démarrer avec Prometheus](https://prometheus.io/docs/prometheus/latest/getting_started/)
- [Superviser Linux avec node_exporter](https://prometheus.io/docs/guides/node-exporter/)
