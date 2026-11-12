# Alertmanager — procédure d'installation

## Description

Alertmanager reçoit les alertes envoyées par Prometheus, les regroupe, supprime les doublons et les transmet aux bons destinataires (e-mail, Slack, webhook…). Cette procédure l'installe à partir du binaire officiel, sous forme de service systemd.

| | |
|---|---|
| **Systèmes** | Linux amd64, arm64 ou armv7 avec systemd (Debian, Ubuntu, RHEL, openSUSE, Arch) |
| **Méthode** | Binaire officiel (GitHub) |
| **Version** | Dernière publiée (0.35.0 au 12/11/2026) |
| **Ports** | 9093/tcp (interface web et API) |
| **Script** | `install_alertmanager.sh` |

## Prérequis

- Une machine Linux 64 bits avec systemd et un accès root.
- Une connexion Internet (bibliothèque commune et archive GitHub).
- Idéalement, un serveur Prometheus déjà installé (voir la procédure `prometheus`).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/alertmanager
sudo bash install_alertmanager.sh
```

Le script récupère la dernière version publiée sur GitHub (ou celle de `ALERTMANAGER_VERSION`, par exemple `sudo ALERTMANAGER_VERSION=0.35.0 bash install_alertmanager.sh`), vérifie sa somme SHA-256, détecte l'architecture (amd64, arm64, armv7), crée l'utilisateur système `alertmanager`, le dossier de données `/var/lib/alertmanager` et le service systemd. Une configuration existante n'est pas écrasée.

## Installation manuelle

### 1. Créer l'utilisateur de service

```bash
sudo useradd --system --no-create-home --shell /usr/sbin/nologin alertmanager
```

### 2. Télécharger et installer le binaire

Version courante le 12/11/2026 : **0.35.0** (vérifier sur la page des versions GitHub). Remplacer `amd64` par `arm64` sur un Raspberry Pi 64 bits.

```bash
VERSION=0.35.0
cd /tmp
wget https://github.com/prometheus/alertmanager/releases/download/v${VERSION}/alertmanager-${VERSION}.linux-amd64.tar.gz
wget https://github.com/prometheus/alertmanager/releases/download/v${VERSION}/sha256sums.txt
grep " alertmanager-${VERSION}.linux-amd64.tar.gz$" sha256sums.txt | sha256sum -c -
tar -xzf alertmanager-${VERSION}.linux-amd64.tar.gz
cd alertmanager-${VERSION}.linux-amd64
sudo install -m 0755 alertmanager amtool /usr/local/bin/
sudo mkdir -p /etc/alertmanager /var/lib/alertmanager
sudo cp alertmanager.yml /etc/alertmanager/
sudo chown -R alertmanager:alertmanager /etc/alertmanager /var/lib/alertmanager
amtool check-config /etc/alertmanager/alertmanager.yml
```

### 3. Créer le service systemd

```bash
sudo nano /etc/systemd/system/alertmanager.service
```

```ini
[Unit]
Description=Prometheus Alertmanager
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=alertmanager
Group=alertmanager
ExecStart=/usr/local/bin/alertmanager \
    --config.file=/etc/alertmanager/alertmanager.yml \
    --storage.path=/var/lib/alertmanager
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now alertmanager
```

### 4. Ouvrir le port

```bash
sudo ufw allow 9093/tcp
```

### 5. Relier Prometheus à Alertmanager

Dans `/etc/prometheus/prometheus.yml` :

```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets: ["localhost:9093"]
```

```bash
sudo systemctl restart prometheus
```

## Vérification

```bash
systemctl status alertmanager
amtool check-config /etc/alertmanager/alertmanager.yml
curl -s http://localhost:9093/-/healthy
```

L'interface web est accessible sur `http://<adresse-du-serveur>:9093`.

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/usr/local/bin/alertmanager`, `/usr/local/bin/amtool` | Binaires |
| `/etc/alertmanager/alertmanager.yml` | Configuration (routes, destinataires) |
| `/etc/systemd/system/alertmanager.service` | Service |

## Dépannage

- Journaux : `journalctl -u alertmanager -f`.
- Après chaque modification de la configuration : `amtool check-config`, puis `sudo systemctl restart alertmanager`.

## Points d'attention

- La configuration fournie dans l'archive est un exemple (récepteur webhook vers `127.0.0.1:5001`) : définir ses propres récepteurs (`receivers`) avant de compter sur les notifications, puis valider avec `amtool check-config`.
- L'interface web et l'API (port 9093) n'ont pas d'authentification : ne pas les exposer hors du réseau d'administration.
- Relu et mis à jour le 12/11/2026 : Alertmanager 0.35.0.

## Sources

- [Documentation Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [Versions publiées](https://github.com/prometheus/alertmanager/releases)
