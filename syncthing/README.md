# Syncthing — procédure d'installation

## Description

Syncthing synchronise des dossiers entre plusieurs appareils (ordinateurs, serveurs, téléphones) directement de pair à pair, sans serveur central ni service en ligne : les échanges sont chiffrés et les appareils s'authentifient mutuellement. Cette procédure l'installe depuis le dépôt officiel et le fait tourner en service pour un utilisateur.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu (dépôt officiel) ; autres distributions via leurs paquets |
| **Méthode** | Dépôt `apt.syncthing.net` (canal `stable-v2`) |
| **Ports** | 22000/tcp+udp (synchronisation), 21027/udp (découverte locale), 8384/tcp (interface, locale) |
| **Script** | `install_syncthing.sh` |

## Prérequis

- Un compte utilisateur sous lequel Syncthing tournera (ici `flavien`).
- Un accès root pour l'installation.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/syncthing
sudo bash install_syncthing.sh
```

Lire les points d'attention : lancé avec `sudo`, le script démarre Syncthing pour `root`.

## Installation manuelle

### 1. Ajouter le dépôt officiel

```bash
sudo apt update
sudo apt install -y curl apt-transport-https
sudo mkdir -p /etc/apt/keyrings
sudo curl -L -o /etc/apt/keyrings/syncthing-archive-keyring.gpg https://syncthing.net/release-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable-v2" \
  | sudo tee /etc/apt/sources.list.d/syncthing.list
sudo apt update
sudo apt install -y syncthing
```

### 2. Démarrer pour un utilisateur

```bash
sudo systemctl enable --now syncthing@flavien
sudo ufw allow syncthing
```

Le profil `syncthing` de `ufw` ouvre les ports 22000 et 21027.

### 3. Accéder à l'interface

L'interface écoute sur `127.0.0.1:8384`. Sur un serveur sans navigateur, passer par un tunnel SSH depuis son poste :

```bash
ssh -L 8384:localhost:8384 flavien@serveur
```

puis ouvrir `http://localhost:8384`. Définir immédiatement un identifiant et un mot de passe : *Actions → Configuration → Interface graphique*.

### 4. Relier deux appareils

1. Sur chaque appareil, afficher son identifiant : *Actions → Afficher mon ID*.
2. Sur l'un d'eux, **Ajouter un appareil** avec l'identifiant de l'autre, puis accepter la demande sur le second.
3. Dans un dossier, onglet **Partage**, cocher l'appareil, puis accepter le dossier de l'autre côté.

## Vérification

```bash
systemctl status syncthing@flavien
```

Dans l'interface, l'appareil distant apparaît **Connecté** et le dossier **À jour**.

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `~/.local/state/syncthing/` | Configuration, clés et base (versions récentes) |
| `~/.config/syncthing/` | Emplacement des anciennes versions |

## Points d'attention

- Le script lance `syncthing@$USER` : avec `sudo`, `$USER` vaut `root`, donc Syncthing tourne en root et synchronise avec ses droits. Il faut indiquer l'utilisateur réel.
- Il ajoute la clé avec `apt-key` (retiré des distributions récentes) et utilise le canal `stable`. Le dépôt propose maintenant `stable-v2` pour Syncthing 2.x.
- Il ouvre le port 8384 alors que l'interface n'écoute que sur `127.0.0.1` par défaut. Si on l'expose, la protéger par un mot de passe et HTTPS.

## Sources

- [Paquets Debian/Ubuntu de Syncthing](https://apt.syncthing.net/)
- [Démarrage automatique (systemd)](https://docs.syncthing.net/users/autostart.html)
