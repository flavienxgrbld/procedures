# Plex Media Server — procédure d'installation

## Description

Plex Media Server organise films, séries, musique et photos, puis les diffuse vers les applications Plex (télévision, téléphone, navigateur), à la maison ou à distance. Le serveur est gratuit ; certaines fonctions demandent l'abonnement Plex Pass. Cette procédure l'installe depuis le dépôt officiel de Plex.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu (dépôt APT) ; RHEL/Fedora (dépôt RPM) |
| **Méthode** | Dépôt officiel `repo.plex.tv` |
| **Ports** | 32400/tcp |
| **Script** | `install_plex.sh` |

## Prérequis

- Un compte Plex (gratuit).
- Les médias accessibles depuis le serveur.
- Un accès root et une connexion Internet.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/plex
sudo bash install_plex.sh
```

Lire les points d'attention : le script utilise l'ancienne clé et l'ancien dépôt.

## Installation manuelle

### 1. Ajouter le dépôt Plex

```bash
sudo apt update
sudo apt install -y curl gpg
curl -fsSL https://downloads.plex.tv/plex-keys/PlexSign.v2.key | sudo gpg --dearmor -o /usr/share/keyrings/plexmediaserver.v2.gpg
echo "deb [signed-by=/usr/share/keyrings/plexmediaserver.v2.gpg] https://repo.plex.tv/deb/ public main" \
  | sudo tee /etc/apt/sources.list.d/plexmediaserver.list
sudo apt update
```

### 2. Installer et démarrer

```bash
sudo apt install -y plexmediaserver
sudo systemctl enable --now plexmediaserver
sudo ufw allow 32400/tcp
```

### 3. Donner accès aux médias

Plex tourne sous l'utilisateur `plex` :

```bash
sudo setfacl -R -m u:plex:rx /srv/medias
```

### 4. Configurer le serveur

La première configuration doit se faire **depuis le réseau local**. Ouvrir `http://<adresse-du-serveur>:32400/web`, se connecter avec son compte Plex, nommer le serveur, puis ajouter les bibliothèques (Films, Séries, Musique) et leurs dossiers.

Si le serveur est distant (sans navigateur sur le même réseau), passer par un tunnel SSH :

```bash
ssh -L 8888:localhost:32400 utilisateur@serveur
```

puis ouvrir `http://localhost:8888/web`.

## Vérification

```bash
systemctl status plexmediaserver
curl -s http://localhost:32400/identity
```

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/` | Base de données, métadonnées, préférences |
| `.../Plex Media Server/Logs/` | Journaux |

## Points d'attention

- Le script importe l'ancienne clé `PlexSign.key` avec `apt-key` (retiré des distributions récentes) et utilise l'ancien dépôt `downloads.plex.tv/repo/deb`. Le dépôt actuel `repo.plex.tv` est signé avec la clé `PlexSign.v2.key` (vérifié le 13/10/2026).
- Sur RHEL, il passe la clé à `rpm -Uvh` au lieu de `rpm --import`, ce qui échoue (erreur ignorée).
- L'accès à distance depuis Internet demande de rediriger le port 32400 sur la box, ou l'option de relais de Plex.

## Sources

- [Installer Plex Media Server](https://support.plex.tv/articles/200288586-installation/)
- [Dépôt Linux de Plex](https://support.plex.tv/articles/235974187-enable-repository-updating-for-supported-linux-server-distributions/)
