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
sudo bash install_plausible.sh
```

Lire les points d'attention : avec la clé secrète du script, Plausible ne démarre pas.

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

- Le script définit `SECRET_KEY_BASE=CHANGE_ME` : Plausible exige une clé d'au moins 64 octets et refuse de démarrer.
- Il utilise l'image `plausible/analytics:latest` et un Compose incomplet. L'édition communautaire est distribuée par le dépôt `plausible/community-edition`, avec la configuration de ClickHouse adaptée.
- Il installe aussi PostgreSQL sur l'hôte alors que la base tourne dans un conteneur, et laisse `BASE_URL=http://localhost:8000`.

## Sources

- [Plausible Community Edition](https://github.com/plausible/community-edition)
- [Documentation Plausible](https://plausible.io/docs)
