# ERPNext — procédure d'installation

## Description

ERPNext est un progiciel de gestion intégré (ERP) libre : comptabilité, ventes, achats, stocks, production, RH et projets. Il repose sur le framework Frappe et s'administre avec l'outil en ligne de commande `bench`. Cette procédure installe ERPNext version 15 pour un environnement de test ou de production.

| | |
|---|---|
| **Systèmes** | Ubuntu 22.04 / 24.04, Debian 12 |
| **Méthode** | Frappe Bench (Python, Node.js, MariaDB, Redis) |
| **Ports** | 8000/tcp (développement), 80/tcp (production derrière Nginx) |
| **Script** | `install_erpnext.sh` |

## Prérequis

- 4 Go de RAM au minimum, 40 Go de disque.
- Un utilisateur non-root disposant de `sudo` (ici `frappe`).
- Une connexion Internet.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/erpnext
sudo bash install_erpnext.sh
```

Lire les points d'attention : en l'état, le script s'arrête avant la fin.

## Installation manuelle

### 1. Créer l'utilisateur

```bash
sudo adduser frappe
sudo usermod -aG sudo frappe
su - frappe
```

### 2. Installer les dépendances

```bash
sudo apt update
sudo apt install -y git python3-dev python3-pip python3-venv pipx redis-server \
  mariadb-server mariadb-client xvfb libfontconfig wkhtmltopdf curl
```

### 3. Configurer MariaDB

```bash
sudo mysql_secure_installation
sudo nano /etc/mysql/mariadb.conf.d/99-frappe.cnf
```

```ini
[mysqld]
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

[mysql]
default-character-set = utf8mb4
```

```bash
sudo systemctl restart mariadb
```

### 4. Installer Node.js et Yarn

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
source ~/.bashrc
nvm install 18
npm install -g yarn
```

### 5. Installer Bench

```bash
pipx install frappe-bench
pipx ensurepath
source ~/.bashrc
bench --version
```

### 6. Créer le bench et le site

```bash
cd ~
bench init --frappe-branch version-15 frappe-bench
cd frappe-bench
bench new-site erp.exemple.local
```

`bench new-site` demande le mot de passe root de MariaDB, puis celui du compte `Administrator` d'ERPNext.

### 7. Installer l'application ERPNext

```bash
bench get-app --branch version-15 erpnext
bench --site erp.exemple.local install-app erpnext
```

### 8. Démarrer

Pour un test :

```bash
bench start
```

L'application répond sur `http://<adresse-du-serveur>:8000`.

Pour la production (Nginx et Supervisor) :

```bash
sudo bench setup production frappe
bench --site erp.exemple.local enable-scheduler
```

## Vérification

Se connecter avec `Administrator` et le mot de passe défini à l'étape 6 : l'assistant de configuration demande la langue, le pays, la devise et l'entreprise.

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `~/frappe-bench/sites/<site>/site_config.json` | Configuration du site (base, clés) |
| `~/frappe-bench/apps/` | Applications Frappe et ERPNext |
| `~/frappe-bench/logs/` | Journaux |

## Dépannage

- Erreur de jeu de caractères à la création du site : la configuration MariaDB de l'étape 3 n'est pas appliquée.
- Sauvegarde : `bench --site erp.exemple.local backup --with-files`.

## Points d'attention

- Le script installe `frappe-bench` avec `pip3 install` : sur Debian 12 et Ubuntu 23.04+, cette commande est refusée (« externally-managed-environment »). Il faut passer par `pipx` (étape 5).
- Il lance les commandes `bench new-site`, `get-app` et `install-app` depuis le dossier personnel de l'utilisateur au lieu du dossier du bench : elles échouent. Il n'installe ni Node.js, ni Yarn, ni wkhtmltopdf, et ne configure pas MariaDB en `utf8mb4`.
- Le script vise la version 14 : la version 15 est la version stable actuelle.
- Le site `erp.exemple.local` doit être résolu par le DNS (ou ajouté dans `/etc/hosts`) pour fonctionner en production, car Nginx sert le site selon son nom.

## Sources

- [Installation de Frappe](https://docs.frappe.io/framework/user/en/installation)
- [Documentation ERPNext](https://docs.erpnext.com/)
