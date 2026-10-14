# Ghost — procédure d'installation

## Description

Ghost est une plateforme de publication moderne pour blogs et newsletters, rapide et centrée sur l'écriture, avec gestion des membres et des abonnements. Cette procédure suit la méthode officielle : Ghost-CLI sur Ubuntu, derrière Nginx, avec MySQL 8.

| | |
|---|---|
| **Systèmes** | Ubuntu 22.04 / 24.04 (méthode officielle) |
| **Méthode** | Ghost-CLI + Node.js + Nginx + MySQL 8 |
| **Dossier** | `/var/www/ghost` |
| **Ports** | 80/tcp et 443/tcp (Nginx) ; Ghost écoute en interne sur 2368 |
| **Script** | `install_ghost.sh` |

## Prérequis

- Un serveur Ubuntu avec 1 Go de RAM au minimum.
- Un nom de domaine pointant vers le serveur (pour HTTPS).
- Un utilisateur non-root avec `sudo`, qui **ne doit pas s'appeler `ghost`**.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/ghost
sudo bash install_ghost.sh
```

Lire les points d'attention : la méthode du script entre en conflit avec Ghost-CLI.

## Installation manuelle

### 1. Créer un utilisateur d'administration

```bash
sudo adduser flavien
sudo usermod -aG sudo flavien
su - flavien
```

### 2. Installer Nginx et MySQL 8

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y nginx mysql-server
sudo ufw allow 'Nginx Full'
```

Définir un mot de passe pour le compte `root` de MySQL (utilisé par Ghost-CLI pour créer sa base) :

```bash
sudo mysql
```

```sql
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'MotDePasseFort';
EXIT;
```

### 3. Installer Node.js (version prise en charge par Ghost)

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash -
sudo apt install -y nodejs
node -v
```

### 4. Installer Ghost-CLI

```bash
sudo npm install -g ghost-cli@latest
```

### 5. Préparer le dossier du site

```bash
sudo mkdir -p /var/www/ghost
sudo chown $USER:$USER /var/www/ghost
sudo chmod 775 /var/www/ghost
cd /var/www/ghost
```

### 6. Installer Ghost

```bash
ghost install
```

Réponses :

| Question | Réponse |
|---|---|
| Blog URL | `https://blog.exemple.fr` |
| MySQL hostname / username / password | `localhost` / `root` / mot de passe de l'étape 2 |
| Ghost database name | `ghost_prod` |
| Set up a ghost MySQL user? | `Y` |
| Set up Nginx? | `Y` |
| Set up SSL? | `Y` (adresse e-mail pour Let's Encrypt) |
| Set up systemd? | `Y` |
| Start Ghost? | `Y` |

### 7. Créer le compte propriétaire

Ouvrir `https://blog.exemple.fr/ghost`, puis créer le compte administrateur du site.

## Vérification

```bash
cd /var/www/ghost
ghost ls
ghost doctor
```

## Commandes utiles

| Commande | Rôle |
|---|---|
| `ghost restart` | Redémarrer |
| `ghost update` | Mettre à jour Ghost |
| `ghost log` | Afficher les journaux |
| `ghost backup` | Sauvegarder contenu et paramètres |

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/var/www/ghost/config.production.json` | Configuration (URL, base, e-mail) |
| `/var/www/ghost/content/` | Thèmes, images, données |

## Dépannage

- `ghost doctor` détecte la plupart des problèmes (droits, version de Node.js, configuration système).
- Pour envoyer des e-mails (invitations, newsletters), configurer un SMTP dans `config.production.json` (section `mail`).

## Points d'attention

- Le script crée un utilisateur système nommé `ghost` et lance `ghost install` avec lui. La documentation de Ghost interdit ce nom, car Ghost-CLI crée lui-même un utilisateur `ghost` pour faire tourner le service : l'installation échoue ou se retrouve avec des droits incohérents. Il faut aussi un compte avec `sudo`.
- Le script installe Node.js 18, qui n'est plus pris en charge par les versions récentes de Ghost.
- Il n'installe ni Nginx, ni MySQL, que Ghost-CLI attend en production. Ghost ne prend pas en charge MariaDB en production.

## Sources

- [Installer Ghost sur Ubuntu](https://docs.ghost.org/install/ubuntu/)
- [Référence Ghost-CLI](https://docs.ghost.org/ghost-cli)
