# ntopng — procédure d'installation

## Description

ntopng est un outil d'analyse du trafic réseau en temps réel : il affiche, dans une interface web, les machines actives, les protocoles et applications utilisés (grâce à nDPI), les volumes échangés et les flux suspects. Cette procédure l'installe depuis le dépôt officiel de ntop.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu (dépôt ntop) ; version plus ancienne dans les dépôts Debian |
| **Méthode** | Dépôt officiel `packages.ntop.org` |
| **Ports** | 3000/tcp (interface web) |
| **Script** | `install_ntopng.sh` |

## Prérequis

- Un accès root et une connexion Internet.
- Pour voir tout le trafic d'un réseau : placer le serveur sur un **port miroir** du commutateur (SPAN), ou l'installer sur la passerelle.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/ntopng
sudo bash install_ntopng.sh
```

Lire les points d'attention : le script demande un paquet qui n'existe pas.

## Installation manuelle

### 1. Ajouter le dépôt ntop

La page `packages.ntop.org` fournit un paquet `apt-ntop.deb` par distribution. Par exemple pour Debian 12 :

```bash
cd /tmp
wget https://packages.ntop.org/apt-stable/bookworm/all/apt-ntop-stable.deb
sudo apt install -y ./apt-ntop-stable.deb
sudo apt update
```

Pour Ubuntu, prendre le paquet correspondant à sa version (dossier `24.04`, `22.04`…).

### 2. Installer ntopng

```bash
sudo apt install -y ntopng
```

### 3. Choisir l'interface à analyser

`/etc/ntopng/ntopng.conf` :

```ini
-i=eth0
-w=3000
```

Remplacer `eth0` par l'interface voulue (`ip a`).

```bash
sudo systemctl enable --now ntopng
sudo systemctl restart ntopng
sudo ufw allow from 192.168.1.0/24 to any port 3000 proto tcp
```

### 4. Première connexion

Ouvrir `http://<adresse-du-serveur>:3000` avec `admin` / `admin` : ntopng impose de changer le mot de passe à la première connexion.

## Vérification

```bash
systemctl status ntopng redis-server
```

Dans l'interface, *Tableau de bord* et *Hôtes* doivent afficher du trafic quelques secondes après le démarrage.

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/ntopng/ntopng.conf` | Options de démarrage |
| `/var/lib/ntopng/` | Données et historiques |

## Dépannage

- Peu de trafic visible : ntopng ne voit que ce qui passe par son interface. Utiliser un port miroir ou l'installer sur la passerelle.
- Journal : `journalctl -u ntopng -f`.

## Points d'attention

- Le script installe `ntopng` et `ntopngd` : ce second paquet n'existe pas, donc l'installation échoue.
- Sans dépôt ntop, il ne pourrait installer que la version fournie par la distribution, souvent ancienne.
- L'édition Community est gratuite ; certaines fonctions (rapports, intégrations avancées) demandent une licence Pro ou Enterprise.

## Sources

- [Installation de ntopng](https://www.ntop.org/guides/ntopng/installation.html)
- [Dépôts de paquets ntop](https://packages.ntop.org/)
