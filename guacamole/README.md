# Apache Guacamole — procédure d'installation

## Description

Apache Guacamole est une passerelle d'accès à distance sans client : depuis un simple navigateur, on se connecte aux machines du réseau en RDP, SSH ou VNC. Cette procédure déploie Guacamole avec Docker Compose (application web, démon `guacd` et base MySQL pour les comptes et connexions).

| | |
|---|---|
| **Systèmes** | Toute distribution avec Docker |
| **Méthode** | Images Docker officielles `guacamole/guacamole` et `guacamole/guacd` |
| **Dossier** | `/opt/guacamole` |
| **Ports** | 8080/tcp (interface web `/guacamole`) |
| **Script** | `install_guacamole.sh` |

## Prérequis

- Docker et Docker Compose installés (voir la procédure `docker`).
- Les machines cibles accessibles depuis le serveur (RDP 3389, SSH 22, VNC 5900).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/guacamole
sudo bash install_guacamole.sh
```

Lire les points d'attention : sans initialisation de la base, la connexion échoue.

## Installation manuelle

### 1. Préparer le dossier

```bash
sudo mkdir -p /opt/guacamole/init
cd /opt/guacamole
```

### 2. Générer le schéma de la base

L'image Guacamole fournit le script SQL qui crée les tables et le compte administrateur :

```bash
sudo docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --mysql | sudo tee init/initdb.sql > /dev/null
```

### 3. Décrire les services

`/opt/guacamole/compose.yaml` :

```yaml
services:
  guacd:
    image: guacamole/guacd:latest
    restart: unless-stopped

  mysql:
    image: mysql:8.0
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: MotDePasseRoot
      MYSQL_DATABASE: guacamole
      MYSQL_USER: guacamole
      MYSQL_PASSWORD: MotDePasseGuac
    volumes:
      - ./init:/docker-entrypoint-initdb.d:ro
      - mysql_data:/var/lib/mysql

  guacamole:
    image: guacamole/guacamole:latest
    restart: unless-stopped
    depends_on:
      - guacd
      - mysql
    ports:
      - "8080:8080"
    environment:
      GUACD_HOSTNAME: guacd
      MYSQL_HOSTNAME: mysql
      MYSQL_DATABASE: guacamole
      MYSQL_USER: guacamole
      MYSQL_PASSWORD: MotDePasseGuac

volumes:
  mysql_data:
```

### 4. Démarrer

```bash
sudo docker compose up -d
sudo ufw allow 8080/tcp
```

Au premier démarrage, MySQL exécute `initdb.sql` (une à deux minutes).

### 5. Première connexion

Ouvrir `http://<adresse-du-serveur>:8080/guacamole` avec le compte `guacadmin` / `guacadmin`, puis **changer ce mot de passe** immédiatement (ou créer un autre administrateur et supprimer `guacadmin`).

### 6. Ajouter une connexion

*Paramètres → Connexions → Nouvelle connexion* :

- **RDP** : nom d'hôte, port 3389, identifiants Windows ; mode de sécurité « Any » et « Ignorer le certificat du serveur » pour un labo ;
- **SSH** : nom d'hôte, port 22, utilisateur (et mot de passe ou clé privée).

## Vérification

```bash
sudo docker compose ps
sudo docker compose logs guacamole | tail -30
```

## Dépannage

- **« Identifiants incorrects » avec guacadmin** : la base n'a pas été initialisée. Le script SQL n'est exécuté qu'à la création du volume : supprimer le volume (`docker compose down -v`), puis relancer `up -d`.
- **Échec de connexion RDP** : vérifier que le bureau à distance est activé sur la cible et que `guacd` peut la joindre.

## Points d'attention

- Le `docker-compose.yml` du script ne fournit pas le script `initdb.sql` à MySQL : la base reste vide, et l'identifiant `guacadmin / guacadmin` qu'il affiche ne fonctionne pas.
- Le script laisse des mots de passe faibles (`root`, `guacamole`) dans le fichier Compose : les remplacer.
- Exposée sur Internet, l'interface doit passer par HTTPS (proxy inverse) et, idéalement, une double authentification (extension TOTP).

## Sources

- [Guacamole avec Docker](https://guacamole.apache.org/doc/gug/guacamole-docker.html)
- [Manuel de Guacamole](https://guacamole.apache.org/doc/gug/)
