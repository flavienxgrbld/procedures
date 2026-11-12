# Bacula — procédure d'installation

## Description

Bacula est une solution de sauvegarde réseau d'entreprise. Un **Director** orchestre les travaux, un **Storage Daemon** écrit les sauvegardes sur disque ou bande, et un **File Daemon** installé sur chaque machine envoie les fichiers. Cette procédure installe les trois composants et la console sur un même serveur Debian.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu |
| **Méthode** | Paquets de la distribution |
| **Ports** | 9101 (Director), 9102 (File Daemon), 9103 (Storage Daemon) |
| **Script** | `install_bacula.sh` |

## Prérequis

- Un accès root et une connexion Internet.
- Un disque ou une partition dédiée aux sauvegardes (ici `/bacula/backup`).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/bacula
sudo bash install_bacula.sh
```

Le script installe MariaDB puis Bacula en préconfigurant **dbconfig-common** (la base du catalogue est créée sans question), crée `/bacula/backup` (ou `BACULA_STORAGE_DIR`), y fait pointer le Storage Daemon, vérifie la syntaxe des trois fichiers de configuration et démarre les services `bacula-director`, `bacula-sd` et `bacula-fd`. Il reste à adapter le `FileSet` et le `Job` (étape 4) puis à lancer une sauvegarde de test (étape 6).

## Installation manuelle

### 1. Installer les composants

```bash
sudo apt update
sudo apt install -y bacula-director bacula-sd bacula-fd bacula-console bacula-director-mysql mariadb-server
```

Pendant l'installation, accepter la configuration de la base avec **dbconfig-common** : elle crée la base du catalogue Bacula.

### 2. Préparer le dossier de sauvegarde

```bash
sudo mkdir -p /bacula/backup
sudo chown -R bacula:bacula /bacula
```

### 3. Pointer le Storage Daemon vers ce dossier

Dans `/etc/bacula/bacula-sd.conf`, bloc `Device` :

```conf
Device {
  Name = FileStorage
  Media Type = File
  Archive Device = /bacula/backup
  LabelMedia = yes
  Random Access = yes
  AutomaticMount = yes
  RemovableMedia = no
  AlwaysOpen = no
}
```

### 4. Définir ce qu'on sauvegarde

Dans `/etc/bacula/bacula-dir.conf`, adapter le `FileSet` (dossiers à inclure ou exclure) et le `Job` de sauvegarde. Vérifier ensuite la syntaxe :

```bash
sudo bacula-dir -t -c /etc/bacula/bacula-dir.conf
sudo bacula-sd -t -c /etc/bacula/bacula-sd.conf
sudo bacula-fd -t -c /etc/bacula/bacula-fd.conf
```

### 5. Démarrer les services

```bash
sudo systemctl enable --now bacula-director bacula-sd bacula-fd
```

### 6. Lancer une sauvegarde de test

```bash
sudo bconsole
```

```text
*label            (créer un volume, par ex. Vol-0001)
*run              (choisir le job, puis « yes »)
*status director
*messages
```

## Vérification

```bash
systemctl status bacula-director bacula-sd bacula-fd
ss -tlnp | grep -E ':910[123]'
ls -lh /bacula/backup
```

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/bacula/bacula-dir.conf` | Director : jobs, planifications, clients, catalogue |
| `/etc/bacula/bacula-sd.conf` | Storage Daemon : emplacement des volumes |
| `/etc/bacula/bacula-fd.conf` | File Daemon (client) |
| `/etc/bacula/bconsole.conf` | Console d'administration |
| `/var/log/bacula/` | Journaux |

## Dépannage

- Mots de passe : chaque composant s'authentifie auprès des autres. Les mots de passe des fichiers `bacula-dir.conf`, `bacula-sd.conf` et `bacula-fd.conf` doivent correspondre deux à deux.
- Journaux : `journalctl -u bacula-director` et `/var/log/bacula/bacula.log`.

## Points d'attention

- La configuration Debian par défaut sauvegarde un `FileSet` d'exemple : l'adapter (dossiers à inclure ou exclure) avant de compter sur les sauvegardes, puis `sudo systemctl reload bacula-director`.
- Les mots de passe entre Director, Storage Daemon, File Daemon et console sont générés par les paquets Debian et doivent rester identiques de part et d'autre : ne pas les modifier dans un seul fichier.
- Pour sauvegarder d'autres machines, installer seulement `bacula-fd` sur chacune, la déclarer comme `Client` dans `bacula-dir.conf` et ouvrir le port 9102 depuis le serveur.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Documentation Bacula](https://www.bacula.org/documentation/documentation/)
- [Bacula sur Debian (wiki)](https://wiki.debian.org/Bacula)
