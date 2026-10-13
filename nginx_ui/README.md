# Nginx UI — procédure d'installation

## Description

Nginx UI est une interface web pour administrer Nginx : création et modification des sites, éditeur de configuration avec vérification, certificats Let's Encrypt, journaux et état du serveur. Cette procédure l'installe avec l'image Docker officielle, qui embarque Nginx.

| | |
|---|---|
| **Systèmes** | Toute distribution avec Docker |
| **Méthode** | Image Docker `uozi/nginx-ui` (Nginx inclus) |
| **Dossier** | `/opt/nginx-ui` |
| **Ports** | 8080/tcp et 8443/tcp (sites et interface) |
| **Script** | `install_nginx_ui.sh` |

## Prérequis

- Docker installé (voir la procédure `docker`).
- Pas d'autre Nginx occupant les mêmes ports sur l'hôte.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/nginx_ui
sudo bash install_nginx_ui.sh
```

Le script démarre le conteneur `nginx-ui` sur les ports 8080 et 8443.

## Installation manuelle

### 1. Préparer le dossier

```bash
sudo mkdir -p /opt/nginx-ui/{nginx,nginx-ui,www}
cd /opt/nginx-ui
```

### 2. Décrire le service

`/opt/nginx-ui/compose.yaml` :

```yaml
services:
  nginx-ui:
    image: uozi/nginx-ui:latest
    container_name: nginx-ui
    restart: unless-stopped
    environment:
      TZ: Europe/Paris
    ports:
      - "8080:80"
      - "8443:443"
    volumes:
      - ./nginx:/etc/nginx
      - ./nginx-ui:/etc/nginx-ui
      - ./www:/var/www
```

Pour que Nginx UI gère directement les ports web standard, publier `80:80` et `443:443` à la place.

### 3. Démarrer

```bash
sudo docker compose up -d
sudo ufw allow 8080/tcp
sudo ufw allow 8443/tcp
```

### 4. Première connexion

Ouvrir `http://<adresse-du-serveur>:8080`. L'assistant de première installation demande de créer le compte administrateur.

## Vérification

```bash
sudo docker compose ps
sudo docker compose logs nginx-ui
```

## Dépannage

- Mise à jour : `sudo docker compose pull && sudo docker compose up -d`.
- Une configuration Nginx invalide est refusée par l'éditeur, qui affiche le résultat de `nginx -t`.

## Points d'attention

- Le script ne monte pas `/etc/nginx-ui`, où Nginx UI enregistre ses comptes et réglages : ils sont perdus si le conteneur est recréé.
- Il crée ses volumes Docker après avoir démarré le conteneur, ce qui est inutile car Docker les crée automatiquement.
- L'interface donne le contrôle complet du serveur web : ne pas l'exposer sur Internet sans HTTPS, et activer la double authentification dans ses préférences.

## Sources

- [Démarrer avec Nginx UI](https://nginxui.com/guide/getting-started.html)
- [Dépôt Nginx UI](https://github.com/0xJacky/nginx-ui)
