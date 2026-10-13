# Alertmanager — procédure d'installation

## Description

Alertmanager reçoit les alertes envoyées par Prometheus, les regroupe, supprime les doublons et les transmet aux bons destinataires (e-mail, Slack, webhook…). Cette procédure l'installe à partir du binaire officiel, sous forme de service systemd.

| | |
|---|---|
| **Systèmes** | Linux x86_64 avec systemd (Debian, Ubuntu, RHEL, openSUSE, Arch) |
| **Méthode** | Binaire officiel (GitHub) |
| **Version** | 0.26.0 |
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

## Installation manuelle

### 1. Créer l'utilisateur de service

```bash
sudo useradd -r -s /bin/bash -m -c "Alertmanager Service" alertmanager
```

### 2. Télécharger et installer le binaire

```bash
cd /tmp
wget https://github.com/prometheus/alertmanager/releases/download/v0.26.0/alertmanager-0.26.0.linux-amd64.tar.gz
tar -xzf alertmanager-0.26.0.linux-amd64.tar.gz
cd alertmanager-0.26.0.linux-amd64
sudo cp alertmanager amtool /usr/local/bin/
sudo mkdir -p /etc/alertmanager
sudo cp alertmanager.yml /etc/alertmanager/
sudo chown -R alertmanager:alertmanager /etc/alertmanager
```

### 3. Créer le service systemd

```bash
sudo nano /etc/systemd/system/alertmanager.service
```

```ini
[Unit]
Description=Alertmanager
After=network.target

[Service]
Type=simple
User=alertmanager
ExecStart=/usr/local/bin/alertmanager --config.file=/etc/alertmanager/alertmanager.yml
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

- Le service écrit ses données dans le dossier courant par défaut. Ajouter `--storage.path=/var/lib/alertmanager` (dossier appartenant à `alertmanager`) pour un emplacement maîtrisé.
- La configuration fournie dans l'archive est un exemple : il faut définir ses propres récepteurs (`receivers`) avant de recevoir des notifications.
- La version 0.26.0 est figée dans le script : vérifier la dernière version sur GitHub.

## Sources

- [Documentation Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [Versions publiées](https://github.com/prometheus/alertmanager/releases)
