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

Le script installe PostgreSQL, ajoute le dépôt officiel Odoo 19, installe le paquet `odoo` et `wkhtmltopdf`, puis remplace le mot de passe maître par défaut par un mot de passe aléatoire (étape 4, enregistré dans `/root/odoo_identifiants.txt`). Il reste à créer la base de l'entreprise dans le navigateur (étape 5). Variables facultatives : `ODOO_VERSION`, `ODOO_MASTER_PASS`.

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

- Odoo ne fonctionne qu'avec **PostgreSQL** (pas MariaDB/MySQL).
- Le gestionnaire de bases (`/web/database/manager`) permet de créer, sauvegarder et **supprimer** des bases : le mot de passe maître doit rester secret ; en production, ajouter `list_db = False` dans `odoo.conf`.
- Pour un accès depuis Internet, publier Odoo derrière Nginx en HTTPS (avec `proxy_mode = True`).
- Relu et mis à jour le 12/11/2026.

## Sources

- [Installer Odoo depuis les paquets](https://www.odoo.com/documentation/19.0/administration/on_premise/packages.html)
- [Déployer Odoo en production](https://www.odoo.com/documentation/19.0/administration/on_premise/deploy.html)
