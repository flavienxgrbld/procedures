# Docker — procédure d'installation

## Description

Docker permet d'exécuter des applications dans des conteneurs isolés et reproductibles. Docker Compose décrit des applications à plusieurs conteneurs dans un fichier YAML. Cette procédure installe Docker Engine et le plugin Compose depuis le dépôt officiel de Docker.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu (dépôt officiel) ; RHEL, openSUSE, Arch (paquets de la distribution) |
| **Méthode** | Dépôt `download.docker.com` |
| **Ports** | Aucun par défaut (les conteneurs publient les leurs) |
| **Script** | `install_docker.sh` |

## Prérequis

- Un système 64 bits, un accès root et une connexion Internet.
- Pas d'anciens paquets `docker.io` ou `docker-compose` de la distribution (voir l'étape 1).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/docker
sudo bash install_docker.sh
```

Le script ajoute l'utilisateur qui l'a lancé avec `sudo` au groupe `docker`.

## Installation manuelle

### 1. Retirer les anciennes versions

```bash
sudo apt remove -y docker.io docker-compose docker-doc podman-docker containerd runc 2>/dev/null || true
```

### 2. Ajouter le dépôt officiel

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt update
```

Sur Ubuntu, remplacer les deux occurrences de `linux/debian` par `linux/ubuntu`.

### 3. Installer Docker et Compose

```bash
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
```

### 4. Utiliser Docker sans sudo

```bash
sudo usermod -aG docker $USER
```

Se déconnecter puis se reconnecter pour que le groupe soit pris en compte.

## Vérification

```bash
docker --version
docker compose version
docker run --rm hello-world
```

## Exemple avec Compose

`compose.yaml` :

```yaml
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    restart: unless-stopped
```

```bash
docker compose up -d
docker compose ps
docker compose logs -f
```

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/docker/daemon.json` | Configuration du démon (à créer si besoin) |
| `/var/lib/docker/` | Images, conteneurs, volumes |

## Dépannage

- **« permission denied » sur `/var/run/docker.sock`** : l'utilisateur n'est pas encore dans le groupe `docker`, ou ne s'est pas reconnecté.
- Journal : `journalctl -u docker -f`.
- Libérer de l'espace : `docker system prune` (supprime les conteneurs arrêtés et les images inutilisées).

## Points d'attention

- Appartenir au groupe `docker` revient à avoir les droits root sur la machine : le réserver aux administrateurs.
- Les ports publiés par Docker contournent les règles `ufw` : n'exposer que ce qui est nécessaire, ou publier sur `127.0.0.1` (`"127.0.0.1:8080:80"`).
- Le script force l'architecture `amd64` dans le dépôt : sur un Raspberry Pi (`arm64`), utiliser la commande de l'étape 2, qui détecte l'architecture.
- Lancé directement en root (sans `sudo`), le script tente d'ajouter un utilisateur `ubuntu` au groupe `docker`.

## Sources

- [Installer Docker Engine sur Debian](https://docs.docker.com/engine/install/debian/)
- [Installer Docker Engine sur Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
- [Documentation Docker Compose](https://docs.docker.com/compose/)
