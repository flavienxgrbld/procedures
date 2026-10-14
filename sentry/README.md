# Sentry (auto-hébergé) — procédure d'installation

## Description

Sentry collecte et regroupe les erreurs et les problèmes de performance des applications (web, mobile, backend) : pile d'appels, contexte, version, utilisateurs touchés, alertes. Cette procédure installe la version auto-hébergée officielle, qui fonctionne avec Docker Compose et une cinquantaine de conteneurs.

| | |
|---|---|
| **Systèmes** | Linux 64 bits avec Docker |
| **Méthode** | Dépôt officiel `getsentry/self-hosted` (script `install.sh`) |
| **Dossier** | `/opt/sentry` |
| **Ports** | 9000/tcp (interface web) |
| **Script** | `install_sentry.sh` (voir les points d'attention) |

## Prérequis

- **4 cœurs et 16 Go de RAM** recommandés (le script refuse de s'installer sous 14 Go), 20 Go de disque libre (plus pour les données).
- Docker et Docker Compose récents (procédure `docker`).
- Pour un usage réel : un nom de domaine et HTTPS (proxy inverse).

## Installation manuelle

### 1. Récupérer la dernière version

```bash
cd /opt
sudo git clone https://github.com/getsentry/self-hosted.git sentry
cd sentry
sudo git checkout $(git tag -l | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1)
```

### 2. Lancer l'installation

```bash
sudo ./install.sh
```

Le script vérifie les ressources, télécharge les images, prépare les bases (PostgreSQL, ClickHouse, Kafka, Redis) puis propose de créer le compte administrateur. Compter 10 à 30 minutes.

### 3. Démarrer

```bash
sudo docker compose up -d
sudo ufw allow from 192.168.1.0/24 to any port 9000 proto tcp
```

### 4. Configurer

Dans `sentry/config.yml` : URL publique (`system.url-prefix`) et serveur SMTP pour les alertes. Puis :

```bash
sudo docker compose restart web worker
```

### 5. Brancher une application

Dans Sentry : **Projects → Create Project**, choisir la plateforme (Python, PHP, JavaScript…), puis suivre l'exemple d'intégration fourni avec le **DSN** du projet. Par exemple en Python :

```bash
pip install sentry-sdk
```

```python
import sentry_sdk
sentry_sdk.init(dsn="http://<clé>@<adresse-du-serveur>:9000/2")
division_par_zero = 1 / 0
```

L'erreur apparaît dans l'onglet **Issues** du projet.

## Vérification

```bash
cd /opt/sentry
sudo docker compose ps
```

## Points d'attention

- Le script `install_sentry.sh` n'installe pas Sentry : il installe `sentry-sdk`, la **bibliothèque cliente** à intégrer dans une application, ainsi que Redis. Aucun serveur Sentry n'est mis en place.
- La version auto-hébergée est lourde (14 Go de RAM au strict minimum). Pour un labo sur une petite machine, une alternative compatible avec les SDK Sentry est GlitchTip, plus légère.
- Mettre à jour en suivant les versions dans l'ordre indiqué par la documentation (certaines versions sont des étapes obligatoires).

## Sources

- [Sentry auto-hébergé](https://develop.sentry.dev/self-hosted/)
- [Dépôt self-hosted](https://github.com/getsentry/self-hosted)
