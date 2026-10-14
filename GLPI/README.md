# GLPI — procédure d'installation

## Description

GLPI est un logiciel libre de gestion des services informatiques (ITSM) : inventaire du parc, gestion des tickets d'assistance, des contrats, des licences et de la base de connaissances. Cette procédure installe GLPI 11.0.4 sur Debian ou Ubuntu avec Apache, PHP 8.2 et MariaDB, avec les dossiers de configuration et de données sortis de la racine web, comme le recommande l'éditeur.

| | |
|---|---|
| **Systèmes** | Debian 11+ / Ubuntu 20.04+ |
| **Méthode** | Archive officielle + Apache + PHP 8.2 (dépôt Sury/Ondřej) + MariaDB |
| **Version** | 11.0.4 |
| **Ports** | 80/tcp |
| **Script** | `install_glpi.sh` |
| **Procédure détaillée** | [`installation glpi.md`](installation%20glpi.md) |

## Prérequis

- Debian 11+ ou Ubuntu 20.04+, avec 2 Go de RAM (4 Go recommandés).
- Un accès root et une connexion Internet.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/GLPI
sudo bash install_glpi.sh
```

Le script demande deux mots de passe : celui du compte `root` de MariaDB et celui de l'utilisateur `glpi` de la base. Il réalise toutes les étapes ci-dessous, sauf l'assistant web.

## Étapes de l'installation

Chaque étape est détaillée, commandes comprises, dans [`installation glpi.md`](installation%20glpi.md).

1. **Mise à jour du système** et installation des outils (`lsb-release`, `curl`, `gnupg2`…).
2. **Ajout du dépôt PHP** : Sury sur Debian, `ppa:ondrej/php` sur Ubuntu. GLPI 11 exige PHP 8.2 minimum.
3. **Installation d'Apache, de PHP 8.2 et de ses extensions** : `curl`, `gd`, `intl`, `ldap`, `mbstring`, `mysql`, `xml`, `zip`, `bz2`, `apcu`, `redis`, `soap`…
4. **Installation et sécurisation de MariaDB**, création de la base `glpi` (`utf8mb4`), de l'utilisateur `glpi` et chargement des fuseaux horaires.
5. **Téléchargement de GLPI 11.0.4** dans `/var/www/html/glpi`.
6. **Séparation des dossiers** : configuration dans `/etc/glpi`, données dans `/var/lib/glpi`, journaux dans `/var/log/glpi`, déclarés dans `inc/downstream.php` et `/etc/glpi/local_define.php`.
7. **Droits** : code en lecture seule (`root`), données et configuration à `www-data`.
8. **Site Apache** publiant `glpi/public`, réécriture d'URL activée, site par défaut désactivé.
9. **Réglages PHP** : `memory_limit = 256M`, `upload_max_filesize = 20M`, `max_execution_time = 300`, `session.cookie_httponly = On`, `date.timezone = Europe/Paris`.

## Fin de l'installation

### 1. Assistant web

Ouvrir `http://<adresse-du-serveur>/` (le site publie directement le dossier `public` de GLPI) et renseigner :

| Champ | Valeur |
|---|---|
| Serveur SQL | `localhost` |
| Utilisateur | `glpi` |
| Mot de passe | celui saisi pendant le script |
| Base | `glpi` |

### 2. Sécuriser l'instance

Se connecter avec `glpi` / `glpi`, puis :

- changer les mots de passe des comptes par défaut `glpi`, `tech`, `normal` et `post-only`, ou désactiver ces comptes ;
- supprimer le programme d'installation :

```bash
sudo rm /var/www/html/glpi/install/install.php
```

### 3. Planifier les actions automatiques

Sans tâche planifiée, GLPI n'exécute ses actions automatiques (e-mails, inventaire, nettoyage) que lorsqu'un utilisateur navigue :

```bash
echo '* * * * * www-data /usr/bin/php /var/www/html/glpi/front/cron.php' | sudo tee /etc/cron.d/glpi
```

Puis, dans *Configuration → Actions automatiques*, passer les actions en mode **CLI**.

## Vérification

```bash
systemctl status apache2 mariadb
php -v
sudo -u www-data php /var/www/html/glpi/bin/console glpi:system:check_requirements
```

Le menu *Configuration → Générale → Système* ne doit signaler aucun problème de sécurité.

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/var/www/html/glpi/` | Code de GLPI |
| `/etc/glpi/` | Configuration (`config_db.php`, `local_define.php`) |
| `/var/lib/glpi/` | Documents, cache, sessions |
| `/var/log/glpi/` | Journaux de GLPI |
| `/etc/apache2/sites-available/glpi.conf` | Site Apache |

## Dépannage

- **Erreur « Web server root directory configuration is not safe »** : le site doit publier `glpi/public` et non `glpi/`.
- Journaux : `/var/log/glpi/php-errors.log` et `/var/log/apache2/error.log`.

## Points d'attention

- Le message de fin du script et la procédure détaillée indiquent l'URL `http://votre-serveur/glpi`. Avec le site Apache créé, GLPI répond à la racine : `http://votre-serveur/`.
- Penser à remplacer `ServerName yourglpi.yourdomain.com` dans `/etc/apache2/sites-available/glpi.conf` par le vrai nom du serveur.
- La version 11.0.4 est figée dans le script : vérifier la dernière version publiée (GLPI 12 est sorti) avant une nouvelle installation.

## Sources

- [Documentation d'installation GLPI](https://glpi-install.readthedocs.io/)
- [Documentation officielle GLPI](https://glpi-project.org/documentation/)
- [Dépôt GLPI](https://github.com/glpi-project/glpi)
