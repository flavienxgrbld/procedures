# Dnsmasq — procédure d'installation

## Description

Dnsmasq est un serveur DNS (cache et résolution locale) et DHCP léger, idéal pour un petit réseau ou un laboratoire. Cette procédure l'installe et le configure comme serveur DNS du réseau local, avec en option la distribution d'adresses IP par DHCP.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu, RHEL/Fedora, openSUSE, Arch |
| **Méthode** | Paquet de la distribution |
| **Ports** | 53/tcp+udp (DNS), 67/udp (DHCP) |
| **Script** | `install_dnsmasq.sh` |

## Prérequis

- Un accès root et une adresse IP fixe pour le serveur (ici `192.168.1.10`).
- Aucun autre serveur DHCP actif sur le réseau si l'on active le DHCP (désactiver celui de la box).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/dnsmasq
sudo bash install_dnsmasq.sh
```

Lire les points d'attention : la configuration écrite par le script doit être corrigée.

## Installation manuelle

### 1. Installer le paquet

```bash
sudo apt update
sudo apt install -y dnsmasq
```

### 2. Libérer le port 53 (Ubuntu)

Sur Ubuntu, `systemd-resolved` occupe déjà le port 53 :

```bash
sudo sed -i 's/^#\?DNSStubListener=.*/DNSStubListener=no/' /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved
```

### 3. Écrire la configuration

```bash
sudo cp /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
sudo nano /etc/dnsmasq.d/lan.conf
```

```conf
# Écoute
interface=eth0
bind-interfaces
listen-address=127.0.0.1,192.168.1.10

# DNS en amont (ne pas lire /etc/resolv.conf)
no-resolv
server=1.1.1.1
server=9.9.9.9
cache-size=1000

# Domaine local
domain=lab.local
local=/lab.local/
expand-hosts

# Enregistrements locaux
address=/nas.lab.local/192.168.1.20

# DHCP (optionnel)
dhcp-range=192.168.1.100,192.168.1.200,12h
dhcp-option=option:router,192.168.1.1
dhcp-option=option:dns-server,192.168.1.10
```

Remplacer `eth0` par le nom de l'interface (`ip a`). Les noms des machines peuvent aussi être déclarés dans `/etc/hosts`, que dnsmasq lit automatiquement.

### 4. Vérifier puis démarrer

```bash
sudo dnsmasq --test
sudo systemctl enable dnsmasq
sudo systemctl restart dnsmasq
```

### 5. Ouvrir le pare-feu

```bash
sudo ufw allow 53/tcp
sudo ufw allow 53/udp
sudo ufw allow 67/udp
```

## Vérification

```bash
systemctl status dnsmasq
dig @192.168.1.10 debian.org +short
dig @192.168.1.10 nas.lab.local +short
cat /var/lib/misc/dnsmasq.leases
```

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/dnsmasq.conf` | Configuration principale |
| `/etc/dnsmasq.d/` | Fichiers de configuration additionnels |
| `/etc/hosts` | Noms locaux servis en DNS |
| `/var/lib/misc/dnsmasq.leases` | Baux DHCP attribués |

## Dépannage

- **« Address already in use »** : un autre service occupe le port 53 (`sudo ss -lunp | grep :53`), souvent `systemd-resolved` (étape 2).
- Journal : `journalctl -u dnsmasq -f`.

## Points d'attention

- Le script écrase `/etc/dnsmasq.conf` avec `resolv-file=/etc/resolv.conf.d/resolv.conf.dnsmasq`. Ce fichier n'existe pas, donc dnsmasq n'a aucun serveur DNS en amont et ne résout pas les noms Internet. La configuration ci-dessus utilise `no-resolv` et des `server=` explicites.
- Le script fait écouter dnsmasq uniquement sur `127.0.0.1` : les autres machines du réseau ne peuvent pas l'interroger, même avec les ports ouverts.
- Sur Ubuntu, le script ne désactive pas l'écoute DNS de `systemd-resolved` : dnsmasq peut refuser de démarrer.

## Sources

- [Documentation dnsmasq](https://thekelleys.org.uk/dnsmasq/doc.html)
- [Page de manuel](https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html)
