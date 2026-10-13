# RequestBin / Webhook.site — procédure

## Description

Un « request bin » fournit une URL unique qui enregistre toutes les requêtes HTTP reçues (en-têtes, corps, paramètres) : c'est pratique pour tester et déboguer des webhooks ou des intégrations d'API. Le projet RequestBin d'origine n'existe plus ; cette procédure installe à la place **Webhook.site**, libre et auto-hébergeable avec Docker Compose.

| | |
|---|---|
| **Systèmes** | Toute distribution avec Docker |
| **Méthode** | Dépôt `webhooksite/webhook.site` (Docker Compose) |
| **Dossier** | `/opt/webhook.site` |
| **Ports** | 8084/tcp |
| **Script** | `install_requestbin.sh` (voir les points d'attention) |

## Prérequis

- Docker et Docker Compose (procédure `docker`), Git.

## Installation manuelle

### 1. Récupérer le projet

```bash
sudo git clone https://github.com/webhooksite/webhook.site.git /opt/webhook.site
cd /opt/webhook.site
```

### 2. Adapter l'adresse publique

Dans `docker-compose.yml`, service `webhook`, remplacer `APP_URL` par l'adresse utilisée dans le navigateur, et désactiver le mode débogage :

```yaml
      - APP_ENV=production
      - APP_DEBUG=false
      - APP_URL=http://<adresse-du-serveur>:8084
```

### 3. Démarrer

```bash
sudo docker compose pull
sudo docker compose up -d
sudo ufw allow 8084/tcp
```

### 4. Utiliser

Ouvrir `http://<adresse-du-serveur>:8084` : une URL unique est générée. Envoyer une requête de test :

```bash
curl -X POST "http://<adresse-du-serveur>:8084/<identifiant>" \
  -H "Content-Type: application/json" \
  -d '{"evenement": "test", "valeur": 42}'
```

La requête apparaît en direct dans la page, avec ses en-têtes et son corps.

## Vérification

```bash
sudo docker compose ps
sudo docker compose logs -f webhook
```

## Points d'attention

- Le script `install_requestbin.sh` clone `github.com/Runscope/requestbin`, qui n'existe plus (vérifié le 13/10/2026). Le clonage échoue silencieusement (`|| true`), puis `pip3 install -r requirements.txt` s'arrête faute de fichier.
- Même disponible, RequestBin était écrit en Python 2. Le script n'installait ni `git` ni `gunicorn`, et utilisait `pip3` dans le Python du système, refusé sur les distributions récentes.
- Un request bin enregistre tout ce qu'on lui envoie, y compris d'éventuels jetons ou données personnelles : le réserver aux tests et ne pas l'exposer publiquement sans nécessité.

## Sources

- [Dépôt Webhook.site](https://github.com/webhooksite/webhook.site)
