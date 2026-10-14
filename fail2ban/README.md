# Fail2ban — procédure d'installation

## Description

Fail2ban surveille les journaux des services (SSH, serveur web, messagerie…) et bannit temporairement, via le pare-feu, les adresses IP qui accumulent les échecs d'authentification. Cette procédure le met en place pour protéger SSH contre les attaques par force brute, avec bannissement prolongé des récidivistes.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu, RHEL/Fedora, openSUSE, Arch |
| **Méthode** | Paquet de la distribution |
| **Ports** | Aucun (agit sur le pare-feu local) |
| **Script** | `install_fail2ban.sh` |

## Prérequis

- Un accès root.
- Un accès de secours à la machine (console, IPMI, Proxmox) au cas où l'on bannirait sa propre adresse pendant les tests.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/fail2ban
sudo bash install_fail2ban.sh
```

Lire les points d'attention : sur Debian 12, la configuration du script empêche Fail2ban de démarrer.

## Installation manuelle

### 1. Installer le paquet

```bash
sudo apt update
sudo apt install -y fail2ban
```

Sur Debian 12, installer aussi `python3-systemd`, qui permet de lire le journal systemd :

```bash
sudo apt install -y python3-systemd
```

### 2. Créer la configuration locale

Ne pas modifier `jail.conf`, remplacé à chaque mise à jour. Créer `/etc/fail2ban/jail.local` avec uniquement ses propres réglages :

```bash
sudo nano /etc/fail2ban/jail.local
```

```ini
[DEFAULT]
# Adresses jamais bannies : la machine et le réseau d'administration
ignoreip = 127.0.0.1/8 ::1 192.168.1.0/24
bantime  = 1h
findtime = 10m
maxretry = 5
# Lecture du journal systemd (Debian 12, Ubuntu récents)
backend  = systemd

[sshd]
enabled = true
port    = ssh

[recidive]
enabled  = true
logpath  = /var/log/fail2ban.log
backend  = auto
bantime  = 1w
findtime = 1d
maxretry = 3
```

### 3. Démarrer le service

```bash
sudo fail2ban-client -t
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban
```

## Vérification

```bash
sudo fail2ban-client status
sudo fail2ban-client status sshd
```

Pour tester, se tromper de mot de passe SSH plusieurs fois depuis une autre machine (hors `ignoreip`) : son adresse apparaît dans la liste *Banned IP list*.

## Commandes utiles

| Commande | Rôle |
|---|---|
| `fail2ban-client status sshd` | Adresses bannies pour SSH |
| `fail2ban-client set sshd unbanip 203.0.113.5` | Débannir une adresse |
| `fail2ban-client set sshd banip 203.0.113.5` | Bannir manuellement |
| `fail2ban-client reload` | Recharger la configuration |

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/fail2ban/jail.local` | Configuration locale (prioritaire sur `jail.conf`) |
| `/etc/fail2ban/filter.d/` | Filtres (expressions de détection) |
| `/var/log/fail2ban.log` | Journal des bannissements |

## Dépannage

- **Le service ne démarre pas** : lancer `sudo fail2ban-client -t` pour afficher l'erreur de configuration.
- **« Have not found any log file for sshd jail »** : le fichier `/var/log/auth.log` n'existe pas, utiliser `backend = systemd`.

## Points d'attention

- Le script règle la règle `sshd` sur `logpath = /var/log/auth.log`. Sur Debian 12, ce fichier n'existe plus par défaut (les journaux passent par journald) : Fail2ban refuse alors de démarrer.
- Le script copie tout `jail.conf` dans `jail.local`, puis y ajoute une seconde section `[sshd]`. Ce doublon complique la lecture et peut être refusé. Un `jail.local` court, ne contenant que les modifications, est la méthode recommandée.
- Le script ne définit pas `ignoreip` : un administrateur qui se trompe de mot de passe peut bannir sa propre adresse.

## Sources

- [Wiki Fail2ban](https://github.com/fail2ban/fail2ban/wiki)
- [Page de manuel jail.conf](https://manpages.debian.org/bookworm/fail2ban/jail.conf.5.en.html)
