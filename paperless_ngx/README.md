# Paperless-ngx — procédure d'installation

## Description

Paperless-ngx transforme ses documents papier en archive numérique consultable : il reçoit les scans, en extrait le texte par reconnaissance de caractères (OCR), puis les classe automatiquement par correspondant, type et étiquettes. Cette procédure l'installe avec le script officiel, qui prépare un déploiement Docker Compose.

| | |
|---|---|
| **Systèmes** | Toute distribution avec Docker |
| **Méthode** | Script officiel `install-paperless-ngx.sh` (Docker Compose) |
| **Dossier** | `/opt/paperless` (au choix pendant l'installation) |
| **Ports** | 8000/tcp |
| **Script** | `install_paperless_ngx.sh` |

## Prérequis

- Docker et Docker Compose installés (procédure `docker`), avec un utilisateur membre du groupe `docker`.
- 2 Go de RAM au minimum (l'OCR est gourmand).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/paperless_ngx
sudo bash install_paperless_ngx.sh
```

Lire les points d'attention : le paquet que le script tente d'installer n'existe pas.

## Installation manuelle

### 1. Lancer le script officiel (sans sudo)

Avec un utilisateur membre du groupe `docker` :

```bash
bash -c "$(curl -L https://raw.githubusercontent.com/paperless-ngx/paperless-ngx/main/install-paperless-ngx.sh)"
```

Réponses conseillées :

| Question | Réponse |
|---|---|
| URL | `http://<adresse-du-serveur>:8000` |
| Port | `8000` |
| Database backend | `postgres` |
| Enable Apache Tika | `yes` si l'on importe des documents Office et des e-mails |
| OCR language | `fra` (ajouter `+eng` si besoin) |
| Target folder | `/opt/paperless` |
| Consume folder | dossier surveillé, par exemple `/srv/paperless/consume` |
| Username / Password | compte administrateur |

Le script télécharge le fichier Compose correspondant, génère la configuration et démarre les conteneurs.

### 2. Ouvrir le pare-feu

```bash
sudo ufw allow 8000/tcp
```

### 3. Importer des documents

- Déposer des PDF ou des images dans le dossier surveillé (*consume*) : ils sont importés automatiquement, puis supprimés de ce dossier.
- Ou utiliser le bouton **Téléverser** de l'interface `http://<adresse-du-serveur>:8000`.

## Vérification

```bash
cd /opt/paperless
docker compose ps
docker compose logs -f webserver
```

Un document importé doit apparaître avec son texte reconnu (recherche plein texte).

## Commandes utiles

| Commande | Rôle |
|---|---|
| `docker compose exec webserver document_exporter ../export` | Exporter tous les documents et métadonnées |
| `docker compose pull && docker compose up -d` | Mettre à jour |

## Points d'attention

- Le script installe Paperless-ngx avec `pip install paperless-ngx` : ce paquet n'est pas publié sur PyPI (vérifié le 13/10/2026), donc l'installation échoue. Il copie ensuite un fichier `config/paperless.conf.example` qui n'existe pas, et son service ne démarre ni Redis, ni le traitement des documents (*consumer*, *celery*).
- Sauvegarder régulièrement l'export (`document_exporter`) : c'est la méthode recommandée pour restaurer ou migrer une installation.

## Sources

- [Installation de Paperless-ngx](https://docs.paperless-ngx.com/setup/)
- [Dépôt Paperless-ngx](https://github.com/paperless-ngx/paperless-ngx)
