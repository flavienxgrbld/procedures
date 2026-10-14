# Node-RED — procédure d'installation

## Description

Node-RED est un outil de programmation visuelle par flux : on relie dans le navigateur des blocs (nœuds) pour connecter des objets connectés, des API, MQTT ou des bases de données, sans écrire beaucoup de code. Il est très utilisé en domotique et en IoT. Cette procédure l'installe avec le script officiel, sous forme de service systemd.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu, Raspberry Pi OS (script officiel) ; RHEL/Fedora (script RPM) |
| **Méthode** | Script officiel `install-update-nodered-deb` (Node.js + Node-RED + service) |
| **Ports** | 1880/tcp |
| **Script** | `install_node_red.sh` |

## Prérequis

- Un **utilisateur non-root** avec `sudo` : Node-RED tourne sous ce compte.
- `curl`, `git` et `build-essential` (certains nœuds se compilent à l'installation).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/node_red
sudo bash install_node_red.sh
```

Lire les points d'attention : le script fait tourner Node-RED en root, avec une version de Node.js en fin de vie.

## Installation manuelle

### 1. Installer les prérequis

```bash
sudo apt update
sudo apt install -y build-essential git curl
```

### 2. Lancer le script officiel (sans sudo)

Connecté avec l'utilisateur qui fera tourner Node-RED :

```bash
bash <(curl -sL https://github.com/node-red/linux-installers/releases/latest/download/install-update-nodered-deb)
```

Le script installe une version de Node.js prise en charge, Node-RED, quelques nœuds utiles, et crée le service `nodered`.

### 3. Sécuriser l'éditeur

```bash
node-red admin hash-pw
```

Saisir un mot de passe, puis copier le résultat dans `~/.node-red/settings.js`, en décommentant le bloc `adminAuth` :

```javascript
adminAuth: {
    type: "credentials",
    users: [{
        username: "admin",
        password: "$2b$08$...hash...",
        permissions: "*"
    }]
},
```

### 4. Démarrer au boot

```bash
sudo systemctl enable --now nodered
sudo ufw allow 1880/tcp
```

### 5. Créer un premier flux

Ouvrir `http://<adresse-du-serveur>:1880`, glisser un nœud **inject** et un nœud **debug**, les relier, puis cliquer sur **Déployer**. Un clic sur le bouton du nœud inject affiche l'horodatage dans l'onglet de débogage.

## Vérification

```bash
systemctl status nodered
node-red --version
```

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `~/.node-red/settings.js` | Configuration (authentification, port, HTTPS) |
| `~/.node-red/flows.json` | Flux créés |
| `~/.node-red/node_modules/` | Nœuds supplémentaires installés |

## Dépannage

- Journal : `node-red-log` ou `journalctl -u nodered -f`.
- Mise à jour : relancer la commande de l'étape 2.

## Points d'attention

- Le script installe Node.js 18, qui n'est plus maintenu.
- Son service ne précise pas d'utilisateur : Node-RED tourne en `root`, donc tout flux (nœud `exec` par exemple) peut agir sur tout le système. Il n'active pas non plus l'authentification de l'éditeur alors que le port 1880 est ouvert.
- Le cas `all)` du script ne correspond à aucun gestionnaire de paquets : sur RHEL/Fedora, Node.js n'est pas installé.

## Sources

- [Installer Node-RED sur Debian et Raspberry Pi](https://nodered.org/docs/getting-started/raspberrypi)
- [Sécuriser Node-RED](https://nodered.org/docs/user-guide/runtime/securing-node-red)
