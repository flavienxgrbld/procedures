# Pi-hole — procédure d'installation

## Description

Pi-hole est un serveur DNS filtrant : déclaré comme DNS du réseau, il bloque les domaines de publicité et de pistage pour toutes les machines, y compris les téléphones et les objets connectés, sans logiciel à installer sur chacune. Il peut aussi servir de serveur DHCP. Cette procédure l'installe avec le script officiel.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu, Raspberry Pi OS, Fedora |
| **Méthode** | Script officiel `install.pi-hole.net` (installateur interactif) |
| **Ports** | 53/tcp+udp (DNS), 80/tcp et 443/tcp (interface web), 67/udp (DHCP optionnel) |
| **Script** | `install_pihole.sh` |

## Prérequis

- Une machine avec une **adresse IP fixe** (ici `192.168.1.10`).
- Un accès root et une connexion Internet.
- Le port 53 libre (voir l'étape 1 sur Ubuntu).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/pihole
sudo bash install_pihole.sh
```

Le script libère le port 53 sur Ubuntu en gardant une résolution de noms fonctionnelle (`/etc/resolv.conf` relié au résolveur de systemd), télécharge l'installateur officiel dans `/root/install-pihole.sh` (relisible) et le lance : ses questions sont celles de l'étape 2. Il ouvre ensuite les ports DNS et web si un pare-feu est actif.

## Installation manuelle

### 1. Libérer le port 53 (Ubuntu)

```bash
sudo sed -i 's/^#\?DNSStubListener=.*/DNSStubListener=no/' /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
```

La dernière commande évite que la machine perde toute résolution de noms (`/etc/resolv.conf` pointait vers `127.0.0.53`, qui ne répond plus).

### 2. Lancer l'installateur

```bash
curl -sSL https://install.pi-hole.net -o install-pihole.sh
less install-pihole.sh       # relire avant d'exécuter
sudo bash install-pihole.sh
```

Réponses :

- interface réseau : celle du réseau local ;
- serveur DNS en amont : par exemple Quad9 ou Cloudflare ;
- liste de blocage proposée par défaut : **oui** ;
- interface web : **oui** ; journalisation des requêtes : selon la politique de confidentialité.

À la fin, l'installateur affiche le **mot de passe de l'interface web**. Pour le changer :

```bash
sudo pihole setpassword
```

### 3. Ouvrir le pare-feu

```bash
sudo ufw allow 53/tcp
sudo ufw allow 53/udp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### 4. Utiliser Pi-hole comme DNS du réseau

Dans la configuration DHCP de la box (ou du serveur DHCP), définir `192.168.1.10` comme **seul** serveur DNS distribué. Les postes le prennent en compte au renouvellement de leur bail.

## Vérification

```bash
pihole status
dig @192.168.1.10 doubleclick.net +short     # doit renvoyer 0.0.0.0
dig @192.168.1.10 debian.org +short          # doit renvoyer une vraie adresse
```

L'interface `http://192.168.1.10/admin` affiche le nombre de requêtes et le pourcentage de blocage.

## Commandes utiles

| Commande | Rôle |
|---|---|
| `pihole -g` | Mettre à jour les listes de blocage |
| `pihole allow exemple.fr` | Autoriser un domaine bloqué à tort |
| `pihole -up` | Mettre à jour Pi-hole |
| `pihole -t` | Suivre les requêtes en direct |

## Points d'attention

- Pi-hole doit être le **seul** DNS distribué aux postes : un second DNS (celui de la box par exemple) contourne en partie le filtrage.
- Ne pas exposer le port 53 sur Internet : un résolveur DNS ouvert peut servir à des attaques par amplification.
- Le serveur Pi-hole doit avoir une adresse IP fixe.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Installation de Pi-hole](https://docs.pi-hole.net/main/basic-install/)
- [Documentation Pi-hole](https://docs.pi-hole.net/)
