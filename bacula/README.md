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

Lire les points d'attention : le script ne démarre pas les bons services.

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

- Le script installe les paquets **Bacula**, mais active les services `bareos-dir` et `bareos-sd`, qui appartiennent à **Bareos** (un autre logiciel, dérivé de Bacula). Ces services n'existent pas : le script s'arrête en erreur. Les bons noms sont `bacula-director` et `bacula-sd`.
- Le paquet `bacula-storage` installé par le script n'existe pas sous ce nom sur Debian : c'est `bacula-sd`.
- Pour sauvegarder d'autres machines, installer seulement `bacula-fd` sur chacune et la déclarer comme `Client` dans `bacula-dir.conf`.

## Sources

- [Documentation Bacula](https://www.bacula.org/documentation/documentation/)
- [Bacula sur Debian (wiki)](https://wiki.debian.org/Bacula)
