# Installation ERPNext

## Description
ERPNext est un ERP/CRM complet open source basé sur le framework Frappe.

## Prérequis
- Ubuntu/Debian Linux (ou distribution compatible avec `apt`)
- Accès root ou un compte avec privilèges sudo
- Connexion Internet
- Un serveur propre ou une VM avec au moins 4 Go de RAM recommandés

## Structure du dossier
- `install_erpnext.sh` : script d’installation automatique
- `README.md` : documentation de la procédure

## Installation

### Lancement du script

Se placer dans le répertoire de la procédure :

```bash
cd /REPO/procedures/erpnext
```

Exécuter le script avec les droits administrateur :

```bash
sudo bash install_erpnext.sh
```

### Ce que fait le script

Le script effectue les actions suivantes :

1. Vérifie que l’utilisateur est root.
2. Détecte le système et le gestionnaire de paquets.
3. Installe les dépendances : `python3`, `python3-dev`, `python3-pip`, `python3-venv`, `git`, `redis-server`, `mariadb-server`, `curl`.
4. Crée l’utilisateur système `erpnext` et le répertoire `/opt/erpnext`.
5. Installe `frappe-bench` via `pip3`.
6. Initialise un bench Frappe dans `/opt/erpnext/erpnext-bench` avec la branche Frappe `version-14`.
7. Crée un nouveau site Frappe `erpnext.local`.
8. Télécharge l’application `erpnext` et l’installe sur le site créé.

### Remarques importantes

- Le site créé par défaut est `erpnext.local`.
- Sur une machine locale, ajoutez une entrée dans `/etc/hosts` :

```bash
127.0.0.1 erpnext.local
```

- Pour un environnement de production, adaptez le nom de domaine et la configuration du serveur web.

## Configuration post-installation

### Démarrer le bench

Après l’installation, accéder au répertoire d’installation :

```bash
cd /opt/erpnext/erpnext-bench
```

Démarrer l’instance en mode développement :

```bash
bench start
```

### Accéder à l’application

Ouvrir le navigateur sur :

```text
http://erpnext.local:8000
```

Si vous utilisez un nom de domaine différent, changez l’URL en conséquence.

### Configuration de base

1. Se connecter avec les identifiants créés lors du `bench new-site`.
2. Configurer les paramètres de la société.
3. Configurer les utilisateurs et les rôles.
4. Mettre en place la base de données et les paramètres de messagerie.

## Vérification

- Vérifier que le site démarre sans erreur :

```bash
cd /opt/erpnext/erpnext-bench
bench start
```

- Vérifier l’accès web :

```text
http://erpnext.local:8000
```

- Vérifier la présence du site dans `sites/` :

```bash
ls /opt/erpnext/erpnext-bench/sites
```

- Vérifier que l’utilisateur `erpnext` existe :

```bash
id erpnext
```

## Dépannage rapide

- Si `bench` n’est pas trouvé :

```bash
python3 -m pip install frappe-bench
```

- Si la base MariaDB ne démarre pas :

```bash
sudo systemctl status mariadb
sudo journalctl -u mariadb --no-pager
```

- Si Redis est indisponible :

```bash
sudo systemctl status redis-server
```

## Documentation

- [ERPNext officiel](https://erpnext.com)
- [Documentation Frappe](https://frappeframework.com/docs)
- [GitHub ERPNext](https://github.com/frappe/erpnext)

## Notes
- Le script installe ERPNext en mode utilitaire de développement/test.
- Pour une installation en production, il est recommandé d’ajouter un serveur web reverse proxy (Nginx), un certificat TLS et une configuration de processus supervisé.
- Adaptez les noms de sites et les domaines selon votre infrastructure.
