# Odoo — procédure d'installation

## Description

Odoo est une suite de gestion d'entreprise (ERP) modulaire : CRM, ventes, facturation, comptabilité, stocks, site web, ressources humaines… L'édition Community est libre. Cette procédure installe Odoo 19 Community depuis le dépôt officiel, avec PostgreSQL.

| | |
|---|---|
| **Systèmes** | Debian 12/13, Ubuntu 22.04/24.04 |
| **Méthode** | Dépôt officiel `nightly.odoo.com` (paquet `odoo`) |
| **Version** | 19.0 Community |
| **Ports** | 8069/tcp (web), 8072/tcp (longpolling / websocket) |
| **Script** | `install_odoo.sh` |

## Prérequis

- 2 Go de RAM au minimum.
- PostgreSQL (installé à l'étape 1).
- Un accès root et une connexion Internet.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/odoo
sudo bash install_odoo.sh
```

Lire les points d'attention : le script installe MariaDB au lieu de PostgreSQL et ne crée pas de configuration.

## Installation manuelle

### 1. Installer PostgreSQL

```bash
sudo apt update
sudo apt install -y postgresql
```

Le paquet Odoo crée lui-même l'utilisateur PostgreSQL `odoo`.

### 2. Ajouter le dépôt Odoo et installer

```bash
wget -q -O - https://nightly.odoo.com/odoo.key | sudo gpg --dearmor -o /usr/share/keyrings/odoo-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/odoo-archive-keyring.gpg] https://nightly.odoo.com/19.0/nightly/deb/ ./" \
  | sudo tee /etc/apt/sources.list.d/odoo.list
sudo apt update
sudo apt install -y odoo
```

### 3. Installer wkhtmltopdf (impression des PDF)

```bash
sudo apt install -y wkhtmltopdf
```

### 4. Protéger le gestionnaire de bases

Dans `/etc/odoo/odoo.conf` :

```ini
[options]
admin_passwd = UnMotDePasseMaitreLong
db_host = False
db_port = False
db_user = odoo
db_password = False
```

`admin_passwd` protège la création, la sauvegarde et la suppression des bases depuis le navigateur.

```bash
sudo systemctl restart odoo
sudo systemctl enable odoo
sudo ufw allow 8069/tcp
```

### 5. Créer la base de l'entreprise

Ouvrir `http://<adresse-du-serveur>:8069`, saisir le mot de passe maître, puis le nom de la base, la langue (français), le pays et le compte administrateur. Installer ensuite les applications voulues (Facturation, CRM, Inventaire…).

## Vérification

```bash
systemctl status odoo postgresql
curl -I http://localhost:8069/web/login
```

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/odoo/odoo.conf` | Configuration |
| `/var/log/odoo/odoo-server.log` | Journal |
| `/var/lib/odoo/` | Fichiers joints (filestore) |

## Dépannage

- Sauvegarder une base : *Gestionnaire de bases* (`/web/database/manager`) → **Backup**, avec le mot de passe maître.
- Pour la production, publier Odoo derrière Nginx en HTTPS et ajouter `proxy_mode = True` dans `odoo.conf`.

## Points d'attention

- Le script appelle `install_database`, qui installe **MariaDB**, alors qu'Odoo ne fonctionne qu'avec **PostgreSQL** : Odoo ne peut pas créer de base.
- Son service lance `odoo-bin -c /opt/odoo/odoo.conf`, mais ce fichier n'est jamais créé.
- Il installe les dépendances Python avec `pip install` dans le Python du système : refusé sur Debian 12 et Ubuntu 23.04 et plus récents (« externally-managed-environment »).
- Il clone la version 16.0, dont la maintenance se termine. La version actuelle est la 19.0.

## Sources

- [Installer Odoo depuis les paquets](https://www.odoo.com/documentation/19.0/administration/on_premise/packages.html)
- [Déployer Odoo en production](https://www.odoo.com/documentation/19.0/administration/on_premise/deploy.html)
