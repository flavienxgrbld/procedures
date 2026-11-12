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

Le script détecte l'interface et l'adresse IP du serveur, libère le port 53 sur Ubuntu (étape 1), installe dnsmasq et écrit `/etc/dnsmasq.d/lan.conf` sur le modèle de l'étape 3 : écoute sur `127.0.0.1` et l'adresse du serveur, DNS en amont explicites, domaine local. Le DHCP n'est activé que si `DHCP_RANGE` est fourni :

```bash
sudo DNS_DOMAIN=lab.local DHCP_RANGE=192.168.1.100,192.168.1.200,12h bash install_dnsmasq.sh
```

| Variable | Défaut |
|---|---|
| `DNS_INTERFACE` / `DNS_IP` | interface de la route par défaut et son adresse |
| `DNS_DOMAIN` | `lab.local` |
| `DNS_UPSTREAM` | `1.1.1.1 9.9.9.9` |
| `DHCP_RANGE` | vide (pas de DHCP) |
| `DHCP_ROUTER` | passerelle actuelle du serveur |

## Installation manuelle

### 1. Libérer le port 53 (Ubuntu)

Sur Ubuntu, `systemd-resolved` occupe déjà le port 53 :

```bash
sudo sed -i 's/^#\?DNSStubListener=.*/DNSStubListener=no/' /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
```

La dernière commande est indispensable : `/etc/resolv.conf` pointait vers `127.0.0.53`, qui ne répond plus, et la machine ne résoudrait plus aucun nom (ni `apt`). Faire cette étape **avant** d'installer le paquet, sinon son service ne démarre pas.

### 2. Installer le paquet

```bash
sudo apt update
sudo apt install -y dnsmasq
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

- Ne jamais activer le DHCP de dnsmasq sur un réseau qui a déjà un serveur DHCP (box, routeur, Windows Server) : deux serveurs DHCP distribuent des adresses contradictoires.
- Le serveur dnsmasq doit avoir une adresse IP **fixe** : c'est elle que les postes utilisent comme DNS.
- `.local` est aussi utilisé par mDNS (Avahi, Bonjour) : sur un réseau avec des Mac ou des imprimantes, préférer un domaine comme `lab.lan` ou `home.arpa`.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Documentation dnsmasq](https://thekelleys.org.uk/dnsmasq/doc.html)
- [Page de manuel](https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html)
