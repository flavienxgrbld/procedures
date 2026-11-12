# Etherpad — procédure d'installation

## Description

Etherpad est un éditeur de texte collaboratif en temps réel : plusieurs personnes écrivent dans le même document, chacune avec sa couleur, avec historique des versions et discussion intégrée. Cette procédure l'installe avec l'image Docker officielle, la méthode la plus simple à maintenir.

| | |
|---|---|
| **Systèmes** | Toute distribution avec Docker |
| **Méthode** | Image Docker officielle `etherpad/etherpad` + PostgreSQL |
| **Ports** | 9001/tcp |
| **Script** | `install_etherpad.sh` |

## Prérequis

- Docker installé (voir la procédure `docker`).
- Un accès root et une connexion Internet.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/etherpad
sudo bash install_etherpad.sh
```

Le script installe Docker s'il est absent, écrit `/opt/etherpad/compose.yaml` (Etherpad + PostgreSQL) et un fichier `/opt/etherpad/.env` avec des mots de passe aléatoires, puis démarre les conteneurs. Relancé plus tard, il met les images à jour en gardant les mots de passe. Variables facultatives : `ETHERPAD_TITLE`, `ETHERPAD_ADMIN_PASS`, `ETHERPAD_PORT`.

## Installation manuelle (Docker)

### 1. Créer le dossier du service

```bash
sudo mkdir -p /opt/etherpad
cd /opt/etherpad
```

### 2. Décrire le service

`/opt/etherpad/compose.yaml` :

```yaml
services:
  etherpad:
    image: etherpad/etherpad:latest
    container_name: etherpad
    restart: unless-stopped
    depends_on:
      - postgres
    ports:
      - "9001:9001"
    environment:
      TITLE: "Etherpad du labo"
      ADMIN_PASSWORD: "MotDePasseFort"
      DB_TYPE: postgres
      DB_HOST: postgres
      DB_PORT: "5432"
      DB_NAME: etherpad
      DB_USER: etherpad
      DB_PASS: "AutreMotDePasseFort"
    volumes:
      - etherpad_var:/opt/etherpad-lite/var

  postgres:
    image: postgres:17
    container_name: etherpad-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: etherpad
      POSTGRES_USER: etherpad
      POSTGRES_PASSWORD: "AutreMotDePasseFort"
    volumes:
      - etherpad_db:/var/lib/postgresql/data

volumes:
  etherpad_var:
  etherpad_db:
```

La base PostgreSQL remplace la base par défaut d'Etherpad (`dirty.db`), réservée aux tests.

### 3. Démarrer

```bash
sudo docker compose up -d
sudo ufw allow 9001/tcp
```

### 4. Utiliser

- Ouvrir `http://<adresse-du-serveur>:9001`, saisir un nom de pad puis **OK** : le lien du pad se partage tel quel.
- L'administration (extensions, paramètres) se trouve sur `http://<adresse-du-serveur>:9001/admin`, avec le compte `admin` et le mot de passe défini dans `ADMIN_PASSWORD`.

## Vérification

```bash
sudo docker compose ps
sudo docker compose logs -f etherpad
curl -I http://localhost:9001
```

## Dépannage

- Le conteneur redémarre en boucle : lire la cause dans `docker compose logs etherpad`.
- Mise à jour : `sudo docker compose pull && sudo docker compose up -d`.

## Points d'attention

- Par défaut, n'importe quel visiteur peut créer et modifier des pads : sur un serveur accessible depuis Internet, activer l'authentification (`REQUIRE_AUTHENTICATION`) ou limiter l'accès au réseau interne.
- Les ports publiés par Docker contournent `ufw` : ne pas compter sur le pare-feu de l'hôte pour masquer le port 9001.
- Pour un accès par Internet, placer Etherpad derrière un proxy inverse HTTPS (le script active déjà `TRUST_PROXY`).
- Relu et mis à jour le 12/11/2026 (Etherpad 3.3).

## Sources

- [Documentation Etherpad](https://docs.etherpad.org/)
- [Dépôt Etherpad](https://github.com/ether/etherpad)
