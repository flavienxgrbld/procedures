# Jitsi Meet — procédure d'installation

## Description

Jitsi Meet est une solution de visioconférence libre, utilisable directement dans le navigateur sans compte : salles à la volée, partage d'écran, discussion, enregistrement en option. Cette procédure installe un serveur Jitsi Meet complet (Prosody, Jicofo, Jitsi Videobridge et Nginx) depuis le dépôt officiel.

| | |
|---|---|
| **Systèmes** | Debian 11/12, Ubuntu 22.04/24.04 |
| **Méthode** | Dépôt officiel `download.jitsi.org` |
| **Ports** | 80/tcp, 443/tcp, 10000/udp (flux audio/vidéo) |
| **Script** | `install_jitsi_meet.sh` |

## Prérequis

- Un serveur dédié avec 4 Go de RAM et 2 cœurs au minimum.
- Un **nom de domaine** (par exemple `visio.exemple.fr`) pointant vers le serveur, ports 80, 443 et 10000/udp accessibles depuis Internet.
- Le nom d'hôte de la machine réglé sur ce domaine.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/jitsi_meet
sudo bash install_jitsi_meet.sh
```

L'installation du paquet `jitsi-meet` pose les questions décrites à l'étape 4.

## Installation manuelle

### 1. Régler le nom d'hôte

```bash
sudo hostnamectl set-hostname visio.exemple.fr
echo "127.0.0.1 visio.exemple.fr" | sudo tee -a /etc/hosts
```

### 2. Ouvrir le pare-feu

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 10000/udp
sudo ufw allow 22/tcp
sudo ufw enable
```

### 3. Ajouter les dépôts

Dépôt Jitsi :

```bash
sudo apt update
sudo apt install -y curl gnupg2 apt-transport-https nginx-full
curl -fsSL https://download.jitsi.org/jitsi-key.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/jitsi-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/" \
  | sudo tee /etc/apt/sources.list.d/jitsi-stable.list
```

Sur Ubuntu, ajouter aussi le dépôt Prosody, dont Jitsi a besoin d'une version récente :

```bash
curl -fsSL https://prosody.im/files/prosody-debian-packages.key | sudo gpg --dearmor -o /usr/share/keyrings/prosody-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/prosody-keyring.gpg] http://packages.prosody.im/debian $(lsb_release -sc) main" \
  | sudo tee /etc/apt/sources.list.d/prosody.list
sudo apt install -y lua5.2
```

```bash
sudo apt update
```

### 4. Installer Jitsi Meet

```bash
sudo apt install -y jitsi-meet
```

Réponses :

| Question | Réponse |
|---|---|
| Nom d'hôte | `visio.exemple.fr` |
| Certificat SSL | **Let's Encrypt** (avec une adresse e-mail) |
| Numéro de téléphone (Jigasi) | laisser vide |

### 5. Réserver la création de salles (recommandé)

Par défaut, n'importe qui peut créer une réunion. Pour l'exiger d'utilisateurs connus, suivre la section « Secure domain » de la documentation officielle (authentification Prosody pour les organisateurs, accès invité pour les participants).

## Vérification

```bash
systemctl status prosody jicofo jitsi-videobridge2 nginx
```

Ouvrir `https://visio.exemple.fr`, créer une salle et la rejoindre depuis deux appareils : le son et la vidéo doivent passer dans les deux sens.

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/jitsi/meet/<domaine>-config.js` | Options de l'interface et des réunions |
| `/etc/prosody/conf.avail/<domaine>.cfg.lua` | Authentification (Prosody) |
| `/etc/jitsi/videobridge/` | Configuration du pont vidéo |

## Dépannage

- **Réunion coupée dès qu'un troisième participant arrive** : le port 10000/udp n'est pas joignable (pare-feu ou redirection de port).
- Derrière une box (NAT) : renseigner les adresses privée et publique dans `/etc/jitsi/videobridge/sip-communicator.properties` (`NAT_HARVESTER_LOCAL_ADDRESS`, `NAT_HARVESTER_PUBLIC_ADDRESS`).
- Journaux : `/var/log/jitsi/`.

## Points d'attention

- Le script ajoute la clé du dépôt avec `apt-key`, retiré des versions récentes de Debian et Ubuntu, et ne règle ni le nom d'hôte ni le dépôt Prosody nécessaire sur Ubuntu.
- Il ouvre toute la plage 10000-20000/udp, alors que Jitsi Videobridge n'utilise que le port 10000/udp.
- Sur RHEL/Fedora, il tente d'installer `jitsi-meet` sans ajouter de dépôt : ce paquet n'existe pas pour ces distributions.

## Sources

- [Guide d'installation Debian/Ubuntu](https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-quickstart)
- [Sécuriser l'accès (Secure domain)](https://jitsi.github.io/handbook/docs/devops-guide/secure-domain)
