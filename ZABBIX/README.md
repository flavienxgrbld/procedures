# Installation ZABBIX

## Description
Ce dossier contient les scripts d'installation pour déployer Zabbix Server et l'agent Zabbix sur une distribution Debian/Ubuntu.

## Prérequis
- Système Linux avec un gestionnaire de paquets supporté : `apt`, `dnf`, `yum`, `zypper` ou `pacman`
- Accès root ou sudo
- Connexion Internet
- Serveur Zabbix configuré avec une base MariaDB/MySQL pour le serveur

## Scripts disponibles
- `install_zabbix.sh` : installe et configure Zabbix Server 7.4 avec MariaDB, Apache et l'interface web
- `install_zabbix_agent.sh` : installe et configure l'agent Zabbix sur un client Linux compatible avec `apt`, `dnf`, `yum`, `zypper` ou `pacman`

## Installation du serveur Zabbix
1. Copier le dossier sur le serveur cible.
2. Donner les droits d'exécution au script :

```bash
chmod +x install_zabbix.sh
```
3. Exécuter le script en tant que root :

```bash
sudo bash install_zabbix.sh
```

Le script réalise les actions suivantes :
- vérifie la distribution et l'accès à `repo.zabbix.com`
- installe le dépôt Zabbix 7.4
- installe `zabbix-server-mysql`, `zabbix-frontend-php`, `zabbix-apache-conf`, `zabbix-sql-scripts`, `zabbix-agent` et `mariadb-server`
- sécurise MariaDB
- crée la base de données `zabbix` et l'utilisateur `zabbix`
- importe le schéma Zabbix
- configure le mot de passe DB dans `/etc/zabbix/zabbix_server.conf`
- active et démarre les services `zabbix-server`, `zabbix-agent` et `apache2`

## Installation de l'agent Zabbix
1. Copier `install_zabbix_agent.sh` sur la machine cliente Debian/Ubuntu.
2. Donner les droits d'exécution :

```bash
chmod +x install_zabbix_agent.sh
```
3. Exécuter le script en tant que root :

```bash
sudo bash install_zabbix_agent.sh
```

Le script demande :
- l'adresse ou l'IP du serveur Zabbix
- le nom d'hôte à utiliser pour l'agent

Il configure ensuite `/etc/zabbix/zabbix_agentd.conf` et démarre le service `zabbix-agent`.

## Vérifications après installation
### Sur le serveur Zabbix
- Vérifier les services :

```bash
systemctl status zabbix-server zabbix-agent apache2
```

- Vérifier l'accès à l'interface web :

```bash
curl -I http://localhost/zabbix
```

- Identifiants par défaut pour l'interface web :
  - Utilisateur : `Admin`
  - Mot de passe : `zabbix`

### Sur l'agent
- Vérifier le service :

```bash
systemctl status zabbix-agent
```

- Vérifier que l'agent peut contacter le serveur :

```bash
zabbix_agentd -t agent.ping
```

## Configuration manuelle supplémentaire
- Ajouter l'hôte dans l'interface Zabbix sous `Configuration → Hosts`
- Associer le template correspondant au système d'exploitation
- Activer les éléments de supervision nécessaires

## Documentation
- Site officiel Zabbix : https://www.zabbix.com
- Documentation Zabbix : https://www.zabbix.com/documentation/current/

## Notes
- Ce script cible Debian 13 / Ubuntu compatibles, mais peut fonctionner sur d'autres versions avec des ajustements.
- Le mot de passe par défaut `Admin/zabbix` doit être changé après la première connexion.
- Pour les environnements de production, configurez HTTPS pour l'interface web et des sauvegardes régulières de la base de données.
