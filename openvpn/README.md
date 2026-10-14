# OpenVPN — procédure d'installation

## Description

OpenVPN est un logiciel libre de réseau privé virtuel (VPN) : il crée un tunnel chiffré entre des postes distants (nomades, télétravailleurs) et le réseau de l'entreprise. L'authentification repose sur une autorité de certification (PKI) gérée avec easy-rsa. Cette procédure installe un serveur OpenVPN en mode routé et crée un premier client.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu |
| **Méthode** | Paquets `openvpn` et `easy-rsa` |
| **Réseau VPN** | `10.8.0.0/24` |
| **Ports** | 1194/udp |
| **Script** | `install_openvpn.sh` |

## Prérequis

- Un serveur avec une adresse IP fixe, joignable depuis Internet sur le port 1194/udp (redirection de port sur la box ou le pare-feu).
- Le réseau local à rendre accessible (ici `192.168.1.0/24`).
- Un accès root.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/openvpn
sudo bash install_openvpn.sh
```

Lire les points d'attention : le script s'arrête dès la copie d'easy-rsa et attend des réponses au clavier.

## Installation manuelle

### 1. Installer les paquets

```bash
sudo apt update
sudo apt install -y openvpn easy-rsa
```

### 2. Créer l'autorité de certification et le certificat du serveur

```bash
make-cadir ~/pki-vpn
cd ~/pki-vpn
./easyrsa init-pki
./easyrsa build-ca nopass          # nom de l'autorité : ex. « CA-VPN-Labo »
./easyrsa build-server-full serveur nopass
./easyrsa gen-dh
openvpn --genkey secret ta.key
```

`build-server-full` crée et signe le certificat du serveur ; confirmer avec `yes`.

### 3. Copier les fichiers du serveur

```bash
sudo mkdir -p /etc/openvpn/server
sudo cp pki/ca.crt pki/issued/serveur.crt pki/private/serveur.key pki/dh.pem ta.key /etc/openvpn/server/
```

### 4. Écrire la configuration du serveur

`/etc/openvpn/server/server.conf` :

```conf
port 1194
proto udp
dev tun

ca ca.crt
cert serveur.crt
key serveur.key
dh dh.pem
tls-crypt ta.key

server 10.8.0.0 255.255.255.0
push "route 192.168.1.0 255.255.255.0"
push "dhcp-option DNS 192.168.1.1"

keepalive 10 120
data-ciphers AES-256-GCM:AES-128-GCM
user nobody
group nogroup
persist-key
persist-tun
status /var/log/openvpn/status.log
verb 3
```

Pour faire passer **tout** le trafic des clients par le VPN, remplacer la route poussée par `push "redirect-gateway def1"`.

### 5. Activer le routage et la traduction d'adresses

```bash
echo 'net.ipv4.ip_forward=1' | sudo tee /etc/sysctl.d/99-vpn.conf
sudo sysctl --system
```

Si les machines du réseau local n'ont pas de route vers `10.8.0.0/24`, masquer les clients VPN derrière l'adresse du serveur (remplacer `eth0` par l'interface du réseau local) :

```bash
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
sudo apt install -y iptables-persistent
```

### 6. Démarrer le serveur

```bash
sudo mkdir -p /var/log/openvpn
sudo systemctl enable --now openvpn-server@server
sudo ufw allow 1194/udp
```

### 7. Créer un client

```bash
cd ~/pki-vpn
./easyrsa build-client-full alice nopass
```

Assembler le fichier `alice.ovpn` :

```bash
{
cat <<EOF
client
dev tun
proto udp
remote vpn.exemple.fr 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
data-ciphers AES-256-GCM:AES-128-GCM
verb 3
EOF
echo "<ca>";        cat pki/ca.crt;                 echo "</ca>"
echo "<cert>";      sed -n '/BEGIN/,/END/p' pki/issued/alice.crt; echo "</cert>"
echo "<key>";       cat pki/private/alice.key;      echo "</key>"
echo "<tls-crypt>"; cat ta.key;                     echo "</tls-crypt>"
} > alice.ovpn
```

Transmettre `alice.ovpn` par un canal sûr, puis l'importer dans le client OpenVPN (OpenVPN Connect, ou `network-manager-openvpn` sous Linux).

### 8. Révoquer un client

```bash
./easyrsa revoke alice
./easyrsa gen-crl
sudo cp pki/crl.pem /etc/openvpn/server/
echo "crl-verify crl.pem" | sudo tee -a /etc/openvpn/server/server.conf
sudo systemctl restart openvpn-server@server
```

## Vérification

```bash
systemctl status openvpn-server@server
ip addr show tun0
sudo cat /var/log/openvpn/status.log
```

Depuis le client connecté : `ping 10.8.0.1`, puis une machine du réseau local.

## Dépannage

- **Connexion qui expire** : le port 1194/udp n'est pas redirigé ou bloqué par un pare-feu.
- **VPN connecté mais réseau local injoignable** : routage désactivé (`sysctl net.ipv4.ip_forward`) ou règle NAT absente.
- Journal : `journalctl -u openvpn-server@server -f`.

## Points d'attention

- Le script copie `/usr/share/easy-rsa/*` avec `cp` sans `-r`. Ce dossier contient un sous-dossier (`x509-types`) : `cp` échoue et le script s'arrête.
- Même corrigé, `build-ca` et `sign-req` attendent des réponses au clavier (nom de l'autorité, confirmation `yes`). Le script ne génère aucun fichier client, n'active pas le routage IP et ne pousse que la route du réseau VPN lui-même, ce qui ne donne accès à rien.
- La PKI (en particulier `pki/private/ca.key`) permet de créer de nouveaux accès : la garder hors du serveur VPN ou la protéger par un mot de passe (sans `nopass`).

## Sources

- [Documentation OpenVPN 2.6](https://openvpn.net/community-resources/reference-manual-for-openvpn-2-6/)
- [Documentation easy-rsa](https://easy-rsa.readthedocs.io/)
