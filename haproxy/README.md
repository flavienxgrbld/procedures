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

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/haproxy
sudo bash install_haproxy.sh
```

Le script écrit une configuration d'exemple pointant vers `127.0.0.1:8001` et `127.0.0.1:8002`. Remplacer ces serveurs par les vrais avant usage (étape 2).

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

- La configuration du script envoie les journaux vers `stdout`, alors qu'HAProxy tourne en tâche de fond (`daemon`) : les journaux sont perdus. Elle répartit aussi vers deux serveurs locaux fictifs (ports 8001 et 8002), ce qui donne une erreur 503 tant qu'ils n'existent pas.
- Le script publie la page `/stats` sur le site lui-même, sans mot de passe : n'importe quel visiteur voit l'architecture. La configuration ci-dessus la place sur un port séparé, protégée par un mot de passe.

## Sources

- [Documentation HAProxy](https://docs.haproxy.org/)
- [Tutoriels de configuration](https://www.haproxy.com/documentation/haproxy-configuration-tutorials/)
