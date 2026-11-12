# Plausible Analytics — procédure d'installation

## Description

Plausible est un outil de mesure d'audience web léger et respectueux de la vie privée : sans cookie ni donnée personnelle, il affiche les visites, les pages vues, les sources de trafic et les pays sur un tableau de bord d'une seule page. Cette procédure installe l'édition communautaire (Community Edition) avec le dépôt officiel Docker Compose.

| | |
|---|---|
| **Systèmes** | Toute distribution avec Docker |
| **Méthode** | Dépôt officiel `plausible/community-edition` (Plausible, PostgreSQL, ClickHouse) |
| **Dossier** | `/opt/plausible-ce` |
| **Ports** | 80/tcp et 443/tcp (HTTPS automatique), ou 8000/tcp derrière un proxy |
| **Script** | `install_plausible.sh` |

## Prérequis

- Docker et Docker Compose (procédure `docker`).
- Un **nom de domaine** (ici `stats.exemple.fr`) pointant vers le serveur.
- Un processeur compatible SSE 4.2, exigé par ClickHouse.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/PLAUSIBLE
sudo PLAUSIBLE_URL=https://stats.exemple.fr bash install_plausible.sh
```

Le script installe Docker s'il est absent, récupère le dépôt officiel `plausible/community-edition` (branche v3.2.1), crée le `.env` de l'étape 2 avec une clé `SECRET_KEY_BASE` de 64 octets, publie les ports 80 et 443 (certificat Let's Encrypt obtenu par Plausible) et démarre les conteneurs. Avec `PLAUSIBLE_TLS=non`, Plausible est publié sur `127.0.0.1:8000`, à placer derrière un proxy HTTPS. Variable facultative : `PLAUSIBLE_VERSION`.

## Installation manuelle

### 1. Récupérer le dépôt officiel

```bash
cd /opt
sudo git clone -b v3.2.1 --single-branch https://github.com/plausible/community-edition plausible-ce
cd plausible-ce
```

### 2. Créer le fichier `.env`

```bash
sudo touch .env
echo "BASE_URL=https://stats.exemple.fr" | sudo tee -a .env
echo "SECRET_KEY_BASE=$(openssl rand -base64 48)" | sudo tee -a .env
echo "HTTP_PORT=80" | sudo tee -a .env
echo "HTTPS_PORT=443" | sudo tee -a .env
```

Avec `HTTP_PORT` et `HTTPS_PORT`, Plausible obtient lui-même un certificat Let's Encrypt pour `BASE_URL`.

### 3. Publier les ports

`compose.override.yml` :

```yaml
services:
  plausible:
    ports:
      - 80:80
      - 443:443
```

### 4. Démarrer

```bash
sudo docker compose up -d
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

### 5. Créer le compte et ajouter un site

Ouvrir `https://stats.exemple.fr`, créer le compte administrateur, ajouter le domaine du site à suivre, puis coller le script de suivi indiqué dans la balise `<head>` du site.

## Vérification

```bash
sudo docker compose ps
sudo docker compose logs -f plausible
```

Une visite du site suivi apparaît en quelques secondes sur le tableau de bord (indicateur « visiteurs en ce moment »).

## Points d'attention

- `BASE_URL` doit être l'adresse publique exacte : le domaine doit pointer vers le serveur pour obtenir le certificat.
- Créer le compte administrateur dès la première visite : l'inscription est ouverte tant qu'aucun compte n'existe.
- ClickHouse, utilisé par Plausible, demande 2 Go de RAM au minimum.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Plausible Community Edition](https://github.com/plausible/community-edition)
- [Documentation Plausible](https://plausible.io/docs)
