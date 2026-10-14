# Mosquitto — procédure d'installation

## Description

Eclipse Mosquitto est un courtier (*broker*) MQTT léger : les objets connectés, capteurs et applications publient des messages sur des sujets (*topics*), et le courtier les distribue à ceux qui y sont abonnés. Il est très utilisé en domotique et en IoT, par exemple avec Home Assistant ou Node-RED. Cette procédure l'installe avec authentification par mot de passe.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu, RHEL/Fedora, openSUSE, Arch |
| **Méthode** | Paquets de la distribution |
| **Ports** | 1883/tcp (MQTT), 9001/tcp (MQTT sur WebSocket, optionnel) |
| **Script** | `install_mosquitto.sh` |

## Prérequis

- Un accès root.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/mosquitto
sudo bash install_mosquitto.sh
```

Lire les points d'attention : avec la configuration du script, aucun client ne peut se connecter.

## Installation manuelle

### 1. Installer le courtier et les clients

```bash
sudo apt update
sudo apt install -y mosquitto mosquitto-clients
```

### 2. Créer les comptes

```bash
sudo mosquitto_passwd -c /etc/mosquitto/passwd domotique
sudo mosquitto_passwd /etc/mosquitto/passwd capteur1
sudo chown root:mosquitto /etc/mosquitto/passwd
sudo chmod 640 /etc/mosquitto/passwd
```

L'option `-c` crée le fichier : ne l'utiliser que pour le premier compte.

### 3. Configurer les ports d'écoute

Laisser `/etc/mosquitto/mosquitto.conf` d'origine et créer `/etc/mosquitto/conf.d/local.conf` :

```conf
listener 1883
allow_anonymous false
password_file /etc/mosquitto/passwd

# Optionnel : MQTT sur WebSocket pour les applications web
listener 9001
protocol websockets
```

`allow_anonymous` et `password_file` s'appliquent à tous les ports d'écoute.

### 4. Redémarrer et ouvrir le pare-feu

```bash
sudo systemctl enable mosquitto
sudo systemctl restart mosquitto
sudo ufw allow from 192.168.1.0/24 to any port 1883 proto tcp
```

## Vérification

Dans un premier terminal, s'abonner :

```bash
mosquitto_sub -h localhost -u domotique -P 'MotDePasse' -t 'maison/#' -v
```

Dans un second, publier :

```bash
mosquitto_pub -h localhost -u capteur1 -P 'MotDePasse' -t 'maison/salon/temperature' -m '21.5'
```

Le message `maison/salon/temperature 21.5` doit apparaître dans le premier terminal.

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/mosquitto/mosquitto.conf` | Configuration principale (inclut `conf.d/`) |
| `/etc/mosquitto/conf.d/` | Configuration locale |
| `/etc/mosquitto/passwd` | Comptes (mots de passe chiffrés) |
| `/var/log/mosquitto/mosquitto.log` | Journal |

## Dépannage

- **« Connection Refused: not authorised »** : identifiants erronés, ou `allow_anonymous false` sans compte.
- Journal en direct : `sudo tail -f /var/log/mosquitto/mosquitto.log`.

## Points d'attention

- Depuis Mosquitto 2.0, un port déclaré avec `listener` refuse les clients anonymes tant que `allow_anonymous true` ou un `password_file` n'est pas configuré. La configuration du script ne définit ni l'un ni l'autre : toutes les connexions sont refusées.
- Le script remplace tout `mosquitto.conf`, ce qui supprime l'inclusion de `/etc/mosquitto/conf.d/`, et donne la propriété de `/etc/mosquitto` à l'utilisateur du service.
- Sur Internet, utiliser MQTT chiffré (port 8883 avec certificat TLS) plutôt que le port 1883 en clair.

## Sources

- [Documentation Mosquitto](https://mosquitto.org/documentation/)
- [Méthodes d'authentification](https://mosquitto.org/documentation/authentication-methods/)
