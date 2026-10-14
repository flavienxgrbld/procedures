# Netdata — procédure d'installation

## Description

Netdata est un outil de supervision en temps réel : installé sur un serveur, il collecte chaque seconde des milliers de métriques (CPU, mémoire, disques, réseau, services, conteneurs) et les affiche dans un tableau de bord web, avec des alertes préconfigurées. Cette procédure l'installe avec le script officiel `kickstart.sh`.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu, RHEL/Fedora, openSUSE, Arch… |
| **Méthode** | Script officiel `kickstart.sh` (paquets natifs quand ils existent) |
| **Ports** | 19999/tcp (tableau de bord) |
| **Script** | `install_netdata.sh` |

## Prérequis

- Un accès root et une connexion Internet.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/netdata
sudo bash install_netdata.sh
```

Le script compile Netdata depuis les sources : c'est long, et la méthode recommandée est celle ci-dessous.

## Installation manuelle

### 1. Lancer le script officiel

```bash
cd /tmp
curl -fsSL https://get.netdata.cloud/kickstart.sh -o kickstart.sh
sudo sh kickstart.sh --stable-channel --disable-telemetry --non-interactive
```

Le script ajoute le dépôt de Netdata et installe le paquet natif de la distribution.

### 2. Limiter l'accès au tableau de bord

Le tableau de bord n'a pas d'authentification. Le réserver au réseau d'administration :

```bash
sudo ufw allow from 192.168.1.0/24 to any port 19999 proto tcp
```

Ou ne l'écouter que localement, en éditant la configuration :

```bash
sudo /etc/netdata/edit-config netdata.conf
```

```ini
[web]
    bind to = 127.0.0.1
```

```bash
sudo systemctl restart netdata
```

### 3. Consulter

Ouvrir `http://<adresse-du-serveur>:19999`.

### 4. (Optionnel) Superviser d'autres services

Netdata détecte automatiquement de nombreux services (Nginx, Apache, MariaDB, Docker…). Pour un service nécessitant des identifiants, éditer son collecteur, par exemple :

```bash
sudo /etc/netdata/edit-config go.d/mysql.conf
```

## Vérification

```bash
systemctl status netdata
curl -s http://localhost:19999/api/v1/info | head -c 300
```

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/netdata/netdata.conf` | Configuration générale |
| `/etc/netdata/go.d/` | Collecteurs de services |
| `/etc/netdata/health.d/` | Règles d'alerte |
| `/var/log/netdata/` | Journaux |

## Dépannage

- Mise à jour : relancer `kickstart.sh`, ou utiliser le gestionnaire de paquets (`apt upgrade`).
- Désinstallation : `sudo sh kickstart.sh --uninstall`.

## Points d'attention

- Le script clone le dépôt Git et compile Netdata, ce qui demande de nombreuses dépendances et plusieurs minutes. Le script officiel `kickstart.sh` installe un paquet précompilé, plus simple à mettre à jour.
- Il ouvre le port 19999 à tout le réseau alors que le tableau de bord n'a pas d'authentification.

## Sources

- [Installer Netdata sur Linux](https://learn.netdata.cloud/docs/netdata-agent/installation/linux/)
- [Configuration de l'agent](https://learn.netdata.cloud/docs/netdata-agent/configuration/)
