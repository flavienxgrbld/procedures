# Nextcloud Talk — procédure d'installation

## Description

Nextcloud Talk ajoute à Nextcloud la discussion instantanée, les appels audio et vidéo, le partage d'écran et les webinaires, sans service extérieur. C'est une application Nextcloud (nom technique `spreed`) : cette procédure l'active sur une instance existante et installe un serveur TURN (coturn), indispensable pour les appels entre réseaux différents.

| | |
|---|---|
| **Systèmes** | Serveur Nextcloud existant (Debian/Ubuntu) |
| **Méthode** | Application Nextcloud `spreed` + serveur TURN coturn |
| **Ports** | 3478/tcp+udp (TURN), en plus de l'accès HTTPS à Nextcloud |
| **Script** | `install_nextcloud_talk.sh` |

## Prérequis

- Un **Nextcloud fonctionnel** en HTTPS. Le dépôt n'a pas de procédure Nextcloud : utiliser l'installation officielle, par exemple Nextcloud AIO, qui inclut déjà Talk et son serveur TURN.
- Un accès root au serveur.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/nextcloud_talk
sudo bash install_nextcloud_talk.sh
```

Le script vérifie la présence de `/var/www/nextcloud`, puis installe et active Talk avec `occ`. Lire les points d'attention : la configuration TURN qu'il écrit n'est pas valide.

## Installation manuelle

### 1. Installer l'application Talk

Dans Nextcloud : *Applications → Communication → Talk → Télécharger et activer*. Ou en ligne de commande :

```bash
cd /var/www/nextcloud
sudo -u www-data php occ app:install spreed
```

### 2. Installer le serveur TURN (coturn)

```bash
sudo apt update
sudo apt install -y coturn
openssl rand -hex 32        # secret partagé à noter
```

`/etc/turnserver.conf` :

```conf
listening-port=3478
fingerprint
use-auth-secret
static-auth-secret=<secret généré>
realm=cloud.exemple.fr
total-quota=0
bps-capacity=0
stale-nonce
no-multicast-peers
```

```bash
sudo systemctl enable --now coturn
sudo ufw allow 3478/tcp
sudo ufw allow 3478/udp
```

### 3. Déclarer le serveur TURN dans Talk

*Paramètres d'administration → Talk* :

- **Serveurs STUN** : `cloud.exemple.fr:3478` ;
- **Serveurs TURN** : `turn:` + `cloud.exemple.fr:3478`, secret = celui de coturn, protocoles UDP et TCP.

Le bouton de test à côté du serveur TURN doit afficher une coche verte.

### 4. (Optionnel) Serveur haute performance

Au-delà de 4 ou 5 participants par appel, Nextcloud recommande le *High Performance Backend* (serveur de signalisation et Janus). Nextcloud AIO peut l'installer automatiquement.

## Vérification

Créer une conversation, lancer un appel vidéo depuis un ordinateur, puis le rejoindre depuis un téléphone en 4G : le son et l'image doivent passer.

## Dépannage

- **L'appel se connecte en local mais pas depuis l'extérieur** : le serveur TURN n'est pas joignable (port 3478 fermé ou non redirigé sur la box) ou le secret est différent.
- Journal de coturn : `journalctl -u coturn -f`.

## Points d'attention

- Le script renvoie vers `install_nextcloud.sh`, qui n'existe pas dans le dépôt : sans Nextcloud déjà installé dans `/var/www/nextcloud`, il s'arrête.
- Il active l'application avec `app:enable` juste après `app:install`, alors que `app:install` l'active déjà.
- La valeur qu'il écrit dans `turn_servers` (un objet avec une liste `servers` vide) ne correspond pas au format attendu par Talk et ne déclare aucun serveur. Les appels entre réseaux différents échouent : il faut configurer le TURN dans l'interface (étape 3).
- Son message final indique `http://votre-serveur/nextcloud` : Talk s'utilise en HTTPS, l'accès à la caméra et au micro étant refusé par les navigateurs en HTTP.

## Sources

- [Installer Nextcloud](https://nextcloud.com/install/)
- [Configurer un serveur TURN pour Talk](https://nextcloud-talk.readthedocs.io/en/latest/TURN/)
