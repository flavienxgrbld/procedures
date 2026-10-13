# Artica — procédure d'installation

## Description

Artica est une solution de proxy, de filtrage web et de sécurité réseau administrable depuis une interface web (proxy Squid, filtrage, DNS, pare-feu, statistiques). Cette procédure prépare un serveur Debian, ajoute le dépôt Artica et installe le paquet.

| | |
|---|---|
| **Systèmes** | Debian (recommandé par l'éditeur) ; essais sur RHEL/openSUSE |
| **Méthode** | Dépôt de paquets Artica |
| **Ports** | 80 et 443 (interface), 3128 (proxy), 8080 et 8443 (consoles) |
| **Script** | `install_artica.sh` |

## Prérequis

- Une machine dédiée (physique ou VM) sous Debian, avec 4 Go de RAM et 2 cœurs au minimum.
- Un accès root et une connexion Internet.
- Une adresse IP fixe : les postes clients seront configurés pour passer par ce proxy.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/artica
sudo bash install_artica.sh
```

Les ports et l'URL du dépôt peuvent être ajustés par variables d'environnement :

```bash
sudo ARTICA_HTTP_PORT=80 ARTICA_PROXY_PORT=3128 ARTICA_REPO_URL=https://download.artica.fr/ bash install_artica.sh
```

| Variable | Valeur par défaut |
|---|---|
| `ARTICA_REPO_URL` | `https://download.artica.fr/` |
| `ARTICA_PACKAGE` | `artica` |
| `ARTICA_SERVICE` | `artica` |
| `ARTICA_HTTP_PORT` / `ARTICA_HTTPS_PORT` | `80` / `443` |
| `ARTICA_PROXY_PORT` | `3128` |

## Installation manuelle

### 1. Installer les outils nécessaires

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg wget lsb-release git apt-transport-https
```

### 2. Ajouter la clé et le dépôt Artica

```bash
sudo mkdir -p /usr/share/keyrings
curl -fsSL https://download.artica.fr/artica.gpg | sudo gpg --dearmor -o /usr/share/keyrings/artica-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/artica-archive-keyring.gpg] https://download.artica.fr/ stable main" \
  | sudo tee /etc/apt/sources.list.d/artica.list
sudo apt update
```

### 3. Installer le paquet et activer le service

```bash
sudo apt install -y artica
sudo systemctl enable --now artica
```

### 4. Ouvrir les ports

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3128/tcp
sudo ufw allow 8080/tcp
sudo ufw allow 8443/tcp
```

### 5. Première connexion

Ouvrir `http://<adresse-du-serveur>` (ou le port de console indiqué par Artica) et suivre l'assistant de configuration : réseau, nom du serveur, compte administrateur, puis activation du proxy.

### 6. Configurer les postes clients

Sur les postes, définir le proxy `<adresse-du-serveur>:3128` (paramètres réseau, GPO ou fichier PAC).

## Vérification

```bash
systemctl status artica
ss -tlnp | grep -E ':(80|443|3128)\b'
curl -x http://<adresse-du-serveur>:3128 -I https://www.debian.org
```

## Dépannage

- Paquet introuvable : le dépôt n'a pas été ajouté (clé absente). Vérifier `/etc/apt/sources.list.d/artica.list`, puis lancer `apt update`.
- Service introuvable : le nom exact du service dépend de la version ; le rechercher avec `systemctl list-unit-files | grep -i artica`.
- Journal du script : `/var/log/install_script.log`.

## Points d'attention

- L'URL du dépôt et le nom du paquet sont des valeurs supposées par le script : si l'ajout du dépôt échoue, le script continue sans installer Artica. Se référer à la documentation officielle pour la méthode adaptée à sa version. L'éditeur fournit aussi une image ISO prête à l'emploi, souvent plus simple en VM.
- Sur une distribution sans paquets gérés (`pacman` ou autre), le script appelle la fonction `fatal`, qui n'existe pas dans la bibliothèque commune : il s'arrête avec une erreur « command not found ».

## Sources

- [Site officiel Artica](https://artica-proxy.com/)
- [Documentation Artica](https://wiki.articatech.com/)
