# WireGuard — procédure d'installation

## Description

WireGuard est un VPN moderne, simple et très rapide, intégré au noyau Linux : chaque machine possède une paire de clés, et la configuration tient en quelques lignes. Cette procédure installe un serveur WireGuard qui donne aux clients distants l'accès au réseau local, et crée un premier client.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu (WireGuard intégré au noyau depuis Linux 5.6) |
| **Méthode** | Paquet `wireguard` |
| **Réseau VPN** | `10.10.0.0/24` |
| **Ports** | 51820/udp |
| **Script** | `install_wireguard.sh` |

## Prérequis

- Un serveur avec une adresse IP publique ou une redirection du port 51820/udp sur la box.
- Le nom de l'interface réseau du serveur (`ip a`, ici `eth0`) et le réseau local à rendre accessible (ici `192.168.1.0/24`).
- Un accès root.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/wireguard
sudo WG_PUBLIC=vpn.exemple.fr bash install_wireguard.sh
```

Le script installe WireGuard, génère les clés du serveur (jamais affichées), écrit `wg0.conf` avec le routage et le NAT vers le réseau local, active le routage IP et démarre `wg-quick@wg0`. Il ajoute ensuite un client avec la prochaine adresse libre, une clé pré-partagée, et crée son fichier `/root/wireguard-clients/client1.conf`, affiché aussi en QR code pour l'application mobile. Pour un autre client : `sudo WG_PUBLIC=vpn.exemple.fr WG_CLIENT=bob bash install_wireguard.sh` (sans couper les connexions en cours). Variables facultatives : `WG_NET`, `WG_PORT`, `WG_DNS`.

## Installation manuelle

### 1. Installer WireGuard

```bash
sudo apt update
sudo apt install -y wireguard
```

### 2. Générer les clés du serveur

```bash
cd /etc/wireguard
umask 077
wg genkey | sudo tee serveur.key | wg pubkey | sudo tee serveur.pub
```

### 3. Générer les clés d'un client

```bash
wg genkey | sudo tee alice.key | wg pubkey | sudo tee alice.pub
```

### 4. Écrire la configuration du serveur

`/etc/wireguard/wg0.conf` :

```ini
[Interface]
Address = 10.10.0.1/24
ListenPort = 51820
PrivateKey = <contenu de serveur.key>
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
# alice
PublicKey = <contenu de alice.pub>
AllowedIPs = 10.10.0.2/32
```

Remplacer `eth0` par l'interface du serveur. Ajouter un bloc `[Peer]` par client, chacun avec sa propre adresse (`10.10.0.3/32`, etc.).

### 5. Activer le routage et démarrer

```bash
echo 'net.ipv4.ip_forward=1' | sudo tee /etc/sysctl.d/99-wireguard.conf
sudo sysctl --system
sudo chmod 600 /etc/wireguard/*.key /etc/wireguard/wg0.conf
sudo systemctl enable --now wg-quick@wg0
sudo ufw allow 51820/udp
sudo ufw route allow in on wg0 out on eth0
```

### 6. Écrire la configuration du client

`alice.conf` (à importer dans l'application WireGuard sur le poste ou le téléphone) :

```ini
[Interface]
PrivateKey = <contenu de alice.key>
Address = 10.10.0.2/32
DNS = 192.168.1.1

[Peer]
PublicKey = <contenu de serveur.pub>
Endpoint = vpn.exemple.fr:51820
AllowedIPs = 10.10.0.0/24, 192.168.1.0/24
PersistentKeepalive = 25
```

`AllowedIPs` liste les réseaux joints par le tunnel. Avec `0.0.0.0/0`, tout le trafic du client passe par le VPN. Sur un téléphone, `qrencode -t ansiutf8 < alice.conf` affiche un QR code à scanner.

## Vérification

```bash
sudo wg show
```

Après connexion du client, la ligne `latest handshake` apparaît pour son *peer*. Depuis le client : `ping 10.10.0.1`, puis une machine du réseau local.

## Dépannage

- **Pas de handshake** : port 51820/udp fermé ou non redirigé, ou clés publiques inversées entre client et serveur.
- **Tunnel établi mais réseau local injoignable** : routage IP désactivé, mauvaise interface dans `PostUp`, ou règle `ufw route` manquante.
- Ajouter un client sans couper les autres : `sudo wg syncconf wg0 <(sudo wg-quick strip wg0)`.

## Points d'attention

- La clé privée du serveur (`/etc/wireguard/serveur.key`) ne doit jamais être communiquée ; chaque client a sa propre paire de clés.
- Le port UDP (51820) doit être redirigé vers le serveur sur la box ou le pare-feu de l'entreprise.
- Pour retirer un accès, supprimer le bloc `[Peer]` du client dans `wg0.conf`, puis `sudo systemctl restart wg-quick@wg0`.
- Relu et mis à jour le 12/11/2026.

## Sources

- [WireGuard — démarrage rapide](https://www.wireguard.com/quickstart/)
- [WireGuard sur Debian (wiki)](https://wiki.debian.org/WireGuard)
