# HAProxy — procédure d'installation

## Description

HAProxy est un répartiteur de charge et un proxy inverse très performant, pour HTTP et TCP. Il distribue les requêtes entre plusieurs serveurs, vérifie leur état et retire automatiquement ceux qui sont hors service. Cette procédure l'installe et le configure devant deux serveurs web, avec une page de statistiques protégée.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu, RHEL/Fedora, openSUSE, Arch |
| **Méthode** | Paquet de la distribution |
| **Ports** | 80/tcp (service), 8404/tcp (statistiques) |
| **Script** | `install_haproxy.sh` |

## Prérequis

- Un accès root.
- Au moins deux serveurs web à répartir (ici `192.168.1.21` et `192.168.1.22`, port 80).

## Installation automatique

Indiquer les serveurs web à répartir :

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/haproxy
sudo HAPROXY_BACKENDS="192.168.1.21:80 192.168.1.22:80" bash install_haproxy.sh
```

Le script installe HAProxy, sauvegarde la configuration d'origine (`haproxy.cfg.orig`), écrit la configuration de l'étape 2 avec ces serveurs, la vérifie (`haproxy -c`) et redémarre le service. La page de statistiques est sur le port 8404, protégée par un mot de passe aléatoire enregistré dans `/root/haproxy_identifiants.txt`. Variables facultatives : `HAPROXY_PORT`, `HAPROXY_CHECK` (chemin testé, défaut `/`), `STATS_PASS`.

## Installation manuelle

### 1. Installer HAProxy

```bash
sudo apt update
sudo apt install -y haproxy
haproxy -v
```

### 2. Écrire la configuration

```bash
sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.orig
sudo nano /etc/haproxy/haproxy.cfg
```

```haproxy
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    option  forwardfor
    timeout connect 5s
    timeout client  50s
    timeout server  50s

frontend web
    bind *:80
    default_backend serveurs_web

backend serveurs_web
    balance roundrobin
    option httpchk GET /
    server web1 192.168.1.21:80 check
    server web2 192.168.1.22:80 check

listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 10s
    stats auth admin:MotDePasseFort
```

### 3. Vérifier puis appliquer

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo systemctl enable haproxy
sudo systemctl restart haproxy
```

### 4. Ouvrir le pare-feu

```bash
sudo ufw allow 80/tcp
sudo ufw allow 8404/tcp
```

## Vérification

```bash
systemctl status haproxy
for i in 1 2 3 4; do curl -s http://localhost/ | head -1; done
```

Avec deux pages d'accueil différentes sur les serveurs, les réponses alternent. La page `http://<adresse-du-serveur>:8404/stats` affiche l'état de chaque serveur (vert : disponible, rouge : hors service).

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/haproxy/haproxy.cfg` | Configuration |
| `/var/log/haproxy.log` | Journal (via rsyslog sur Debian et Ubuntu) |

## Dépannage

- **Erreur 503** : aucun serveur du backend ne répond au contrôle `check`. Vérifier sur la page de statistiques.
- Recharger sans couper les connexions : `sudo systemctl reload haproxy`.

## Points d'attention

- Un serveur est retiré de la répartition dès que sa vérification (`option httpchk`) échoue : si tous échouent, HAProxy répond 503. Choisir pour `HAPROXY_CHECK` une page qui répond 200 sur chaque serveur.
- Les serveurs web voient l'adresse d'HAProxy comme client : l'adresse réelle est dans l'en-tête `X-Forwarded-For` (`option forwardfor`), à exploiter dans leurs journaux.
- Ne pas exposer le port 8404 hors du réseau d'administration.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Documentation HAProxy](https://docs.haproxy.org/)
- [Tutoriels de configuration](https://www.haproxy.com/documentation/haproxy-configuration-tutorials/)
