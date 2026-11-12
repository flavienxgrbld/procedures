# Cacti — procédure d'installation

## Description

Cacti est un outil de supervision qui interroge les équipements réseau en SNMP et trace des graphiques d'utilisation (bande passante, CPU, mémoire…) à partir de RRDtool. Cette procédure l'installe sur une pile Apache, PHP et MariaDB.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu |
| **Méthode** | Archive officielle 1.2.26 (script) ou paquet Debian `cacti` (manuel) |
| **Ports** | 80/tcp (interface web), 161/udp vers les équipements supervisés |
| **Script** | `install_cacti.sh` |

## Prérequis

- Un accès root et une connexion Internet.
- Des équipements avec SNMP activé et la communauté (ou les identifiants SNMPv3) correspondante.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/cacti
sudo bash install_cacti.sh
```

Le script installe MariaDB, préconfigure le paquet Debian `cacti` (serveur web Apache, base créée par **dbconfig-common**), installe Cacti, SNMP et RRDtool, puis applique les réglages de l'étape 2 : fuseau horaire identique pour PHP et MariaDB (celui du système, ou `CACTI_TIMEZONE`), `memory_limit`, `max_execution_time` et jeu de caractères `utf8mb4`. Il reste à terminer l'assistant web (étape 3).

## Installation manuelle (paquet Debian, recommandée)

Le paquet `cacti` de Debian installe et configure Apache, PHP, la base de données et la tâche de collecte.

### 1. Installer MariaDB, puis Cacti

```bash
sudo apt update
sudo apt install -y mariadb-server
sudo apt install -y cacti snmp snmpd rrdtool
```

À l'installation :

- serveur web à configurer : **apache2** ;
- configurer la base avec **dbconfig-common** : **Oui**, puis choisir un mot de passe pour l'utilisateur `cacti`.

### 2. Régler le fuseau horaire de PHP et MariaDB

Cacti vérifie que les deux sont identiques. Dans `/etc/php/*/apache2/php.ini` et `/etc/php/*/cli/php.ini` :

```ini
date.timezone = Europe/Paris
memory_limit = 512M
max_execution_time = 60
```

```bash
sudo mysql_tzinfo_to_sql /usr/share/zoneinfo | sudo mysql -u root mysql
sudo mysql -u root -e "GRANT SELECT ON mysql.time_zone_name TO 'cacti'@'localhost'; FLUSH PRIVILEGES;"
sudo systemctl restart apache2 mariadb
```

### 3. Terminer l'installation dans le navigateur

Ouvrir `http://<adresse-du-serveur>/cacti`, se connecter avec `admin` / `admin`, changer le mot de passe, puis suivre l'assistant de vérification des prérequis.

### 4. Ajouter un équipement

*Console → Create → New Device* : renseigner l'adresse IP, la version SNMP et la communauté, puis créer les graphiques proposés.

## Vérification

```bash
systemctl status apache2 mariadb
snmpwalk -v2c -c public <ip-equipement> system
```

Les premiers graphiques apparaissent après quelques cycles de collecte (5 minutes par défaut).

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/usr/share/cacti/` | Application (paquet Debian) |
| `/etc/cacti/debian.php` | Connexion à la base |
| `/etc/cron.d/cacti` | Collecte périodique (poller) |
| `/var/log/cacti/` | Journaux |

## Dépannage

- Graphiques vides : vérifier que le poller tourne (`cat /etc/cron.d/cacti`) et que `snmpwalk` répond depuis le serveur.
- Journal : *Console → Utilities → View Cacti Log*.

## Points d'attention

- La version de Cacti est celle de la distribution, souvent en retard de quelques versions (vérifier avec `apt policy cacti`). Pour la toute dernière version (1.2.31 au 12/11/2026), il faut l'archive de cacti.net et une configuration entièrement manuelle (base, `include/config.php`, poller) : la méthode par paquet reste plus simple à maintenir.
- Le compte `admin` / `admin` est actif tant que l'assistant n'a pas été terminé : le faire dès la fin de l'installation.
- `snmpd` écoute par défaut sur `127.0.0.1` seulement ; c'est suffisant pour superviser le serveur lui-même.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Documentation Cacti](https://docs.cacti.net/)
- [Prérequis d'installation](https://docs.cacti.net/Requirements.md)
