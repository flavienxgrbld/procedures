# Mastodon — procédure d'installation

## Description

Mastodon est un réseau social libre et décentralisé, membre du « fédivers » : chaque serveur (instance) est indépendant mais communique avec les autres. Cette procédure déploie une instance avec le fichier Docker Compose fourni dans le dépôt officiel.

| | |
|---|---|
| **Systèmes** | Toute distribution avec Docker |
| **Méthode** | Docker Compose du dépôt officiel (web, streaming, sidekiq, PostgreSQL, Redis) |
| **Dossier** | `/opt/mastodon` |
| **Ports** | 80/tcp et 443/tcp via un proxy inverse (Mastodon écoute en interne sur 3000 et 4000) |
| **Script** | `install_mastodon.sh` |

## Prérequis

- 4 Go de RAM au minimum, 2 cœurs, de l'espace pour les médias.
- Un **nom de domaine** définitif : il ne peut plus être changé après l'installation.
- Un **serveur SMTP** pour les e-mails de confirmation.
- Docker et Docker Compose (procédure `docker`), Nginx et Certbot (procédures `nginx` et `certbot`).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/mastodon
sudo bash install_mastodon.sh
```

Le script récupère le code et prépare `.env.production`. La configuration et le démarrage se font ensuite avec les étapes 2 à 5.

## Installation manuelle

### 1. Récupérer la dernière version

```bash
sudo git clone https://github.com/mastodon/mastodon.git /opt/mastodon
cd /opt/mastodon
sudo git checkout $(git tag -l 'v4.*' | grep -v rc | sort -V | tail -1)
```

### 2. Générer la configuration

```bash
sudo touch .env.production
sudo docker compose run --rm web bundle exec rake mastodon:setup
```

L'assistant demande le domaine, la base de données (`db`, utilisateur `postgres`), Redis (`redis`), le stockage des médias, le serveur SMTP, puis crée la base et le compte administrateur. Il affiche la configuration à la fin : la copier dans `.env.production` si elle n'a pas été écrite.

### 3. Démarrer Mastodon

```bash
sudo chown -R 991:991 public/system
sudo docker compose up -d
```

### 4. Publier derrière Nginx en HTTPS

Copier le modèle fourni, puis remplacer `example.com` par le domaine :

```bash
sudo cp /opt/mastodon/dist/nginx.conf /etc/nginx/sites-available/mastodon
sudo sed -i 's/example.com/social.exemple.fr/g' /etc/nginx/sites-available/mastodon
sudo ln -s /etc/nginx/sites-available/mastodon /etc/nginx/sites-enabled/
sudo certbot --nginx -d social.exemple.fr
sudo systemctl reload nginx
```

### 5. Se connecter

Ouvrir `https://social.exemple.fr` et se connecter avec le compte administrateur créé à l'étape 2. L'administration se trouve dans *Préférences → Administration*.

## Vérification

```bash
cd /opt/mastodon
sudo docker compose ps
sudo docker compose logs -f web
```

## Commandes utiles

| Commande | Rôle |
|---|---|
| `docker compose run --rm web bin/tootctl accounts create pseudo --email a@b.fr --confirmed --role Owner` | Créer un compte administrateur |
| `docker compose run --rm web bin/tootctl media remove --days 7` | Purger le cache des médias distants |

## Points d'attention

- Le script installe `docker.io` et `docker-compose` (ancienne version 1), clone la branche de développement (`main`) au lieu d'une version publiée, et copie un fichier `docker-compose.yml.example` qui n'existe pas : le fichier Compose est déjà fourni sous le nom `docker-compose.yml`.
- Il ne génère pas les secrets ni la base : sans l'étape 2 (`mastodon:setup`), l'instance ne démarre pas.
- Le cache des médias venant d'autres instances grossit vite : planifier `tootctl media remove`.

## Sources

- [Documentation d'installation Mastodon](https://docs.joinmastodon.org/admin/install/)
- [Dépôt Mastodon](https://github.com/mastodon/mastodon)
