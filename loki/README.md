# Grafana Loki — procédure d'installation

## Description

Loki est le système de centralisation des journaux de Grafana Labs. Il stocke les journaux de toutes les machines et permet de les rechercher et de les afficher dans Grafana, à la manière de Prometheus pour les métriques. Cette procédure installe Loki depuis le dépôt APT de Grafana et envoie les journaux d'une machine avec Grafana Alloy.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu (dépôt Grafana) ; RHEL (dépôt RPM Grafana) |
| **Méthode** | Dépôt officiel `apt.grafana.com` |
| **Ports** | 3100/tcp (API) |
| **Script** | `install_loki.sh` |

## Prérequis

- Un accès root et une connexion Internet.
- Grafana pour consulter les journaux (procédure `tig_stack`, ou installation de Grafana seule).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/loki
sudo bash install_loki.sh
```

Le script ajoute le dépôt Grafana, installe le paquet `loki` avec sa configuration pour serveur unique (stockage TSDB sur disque local), démarre le service, attend que l'API réponde et, si `ufw` est actif, n'ouvre le port 3100 qu'au réseau local (ou à `LOKI_ALLOW_FROM`). Il reste à installer Grafana Alloy sur les machines à surveiller (étape 4).

## Installation manuelle

### 1. Ajouter le dépôt Grafana

```bash
sudo apt update
sudo apt install -y gpg wget
sudo mkdir -p /etc/apt/keyrings
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" \
  | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt update
```

### 2. Installer Loki

```bash
sudo apt install -y loki
sudo systemctl enable --now loki
```

Le paquet fournit une configuration fonctionnelle pour un serveur unique (`/etc/loki/config.yml`, stockage sur disque local).

### 3. Ouvrir le port aux machines qui envoient des journaux

```bash
sudo ufw allow from 192.168.1.0/24 to any port 3100 proto tcp
```

Loki n'a pas d'authentification par défaut : ne pas ouvrir ce port à tout Internet.

### 4. Envoyer des journaux avec Grafana Alloy

Sur chaque machine à surveiller (avec le même dépôt Grafana) :

```bash
sudo apt install -y alloy
```

Dans `/etc/alloy/config.alloy`, collecter le journal systemd et l'envoyer à Loki :

```alloy
loki.source.journal "systeme" {
  forward_to = [loki.write.serveur.receiver]
  labels     = { job = "journal", host = constants.hostname }
}

loki.write "serveur" {
  endpoint {
    url = "http://192.168.1.40:3100/loki/api/v1/push"
  }
}
```

```bash
sudo usermod -aG systemd-journal alloy
sudo systemctl enable --now alloy
sudo systemctl restart alloy
```

### 5. Consulter les journaux dans Grafana

*Connections → Data sources → Add data source → Loki*, URL `http://192.168.1.40:3100`. Dans *Explore*, choisir Loki, puis lancer une requête comme `{job="journal"}`.

## Vérification

```bash
curl -s http://localhost:3100/ready
curl -s http://localhost:3100/loki/api/v1/labels
```

`/ready` doit répondre `ready`, et la liste des étiquettes doit contenir `job` une fois Alloy démarré.

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/loki/config.yml` | Configuration de Loki |
| `/var/lib/loki/` | Données (index et journaux) |
| `/etc/alloy/config.alloy` | Configuration de l'agent de collecte |

## Dépannage

- Journal : `journalctl -u loki -f`. Une erreur `field ... not found` indique un paramètre qui n'existe plus dans cette version de Loki.

## Points d'attention

- Loki n'a pas d'authentification par défaut : n'ouvrir le port 3100 qu'aux machines qui envoient des journaux.
- Promtail, l'ancien agent de collecte de Loki, est en fin de vie : utiliser Grafana Alloy (étape 4).
- La configuration du paquet conserve les journaux sur le disque local sans limite de durée : régler `limits_config.retention_period` et activer le compactage pour éviter de remplir le disque.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Installer Loki (paquets)](https://grafana.com/docs/loki/latest/setup/install/local/)
- [Envoyer des journaux avec Alloy](https://grafana.com/docs/alloy/latest/tutorials/send-logs-to-loki/)
