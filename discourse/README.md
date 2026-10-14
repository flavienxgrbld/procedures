# Discourse — procédure d'installation

## Description

Discourse est une plateforme de forum et de discussion moderne (fils de discussion, notifications, modération, authentification unique). L'éditeur ne prend en charge officiellement que l'installation par conteneur Docker, pilotée par l'outil `discourse_docker`, que suit cette procédure.

| | |
|---|---|
| **Systèmes** | Ubuntu LTS ou Debian 64 bits |
| **Méthode** | Docker (dépôt officiel `discourse_docker`) |
| **Dossier** | `/var/discourse` |
| **Ports** | 80/tcp et 443/tcp |
| **Script** | `install_discourse.sh` |

## Prérequis

- 2 Go de RAM au minimum (ou 1 Go avec un fichier d'échange), 2 cœurs, 20 Go de disque.
- Un **nom de domaine** pointant vers le serveur (par exemple `forum.exemple.fr`).
- Un **serveur SMTP** fonctionnel : Discourse ne peut pas créer de compte sans envoi d'e-mails (Brevo, Mailgun, SMTP de l'hébergeur…).
- Les ports 80 et 443 libres et joignables depuis Internet (certificat Let's Encrypt automatique).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/discourse
sudo bash install_discourse.sh
```

Le script installe Docker et Git, clone `discourse_docker` puis lance l'assistant `discourse-setup`. Ce dernier pose les questions décrites à l'étape 3 ci-dessous.

## Installation manuelle

### 1. Installer Docker et Git

```bash
sudo apt update
sudo apt install -y git
curl -fsSL https://get.docker.com | sudo sh
```

### 2. Récupérer l'outil d'installation officiel

```bash
sudo git clone https://github.com/discourse/discourse_docker.git /var/discourse
cd /var/discourse
sudo chmod 700 containers
```

### 3. Lancer l'assistant

```bash
sudo ./discourse-setup
```

L'assistant demande :

| Question | Exemple |
|---|---|
| Hostname | `forum.exemple.fr` |
| Email address for admin account(s) | `admin@exemple.fr` |
| SMTP server address | `smtp-relay.brevo.com` |
| SMTP port / user / password | `587` / identifiants SMTP |
| Notification email address | `noreply@exemple.fr` |
| Let's Encrypt account email | `admin@exemple.fr` |

Il génère `containers/app.yml`, construit l'image puis démarre le conteneur (de 5 à 15 minutes).

### 4. Créer le compte administrateur

Ouvrir `https://forum.exemple.fr`, cliquer sur **Register**, utiliser l'adresse e-mail admin déclarée, puis valider le lien reçu par e-mail.

## Vérification

```bash
cd /var/discourse
sudo ./launcher logs app | tail -50
sudo docker ps
```

## Commandes utiles

| Commande | Rôle |
|---|---|
| `sudo ./launcher rebuild app` | Appliquer une modification de `app.yml` ou mettre à jour |
| `sudo ./launcher enter app` | Ouvrir un shell dans le conteneur |
| `sudo ./launcher restart app` | Redémarrer |

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/var/discourse/containers/app.yml` | Configuration (domaine, SMTP, plugins) |
| `/var/discourse/shared/standalone/` | Données (base, envois, sauvegardes) |

## Dépannage

- **Pas d'e-mail reçu** : vérifier les paramètres SMTP dans `app.yml`, puis lancer `./launcher rebuild app`. Le menu *Admin → E-mails* propose un envoi de test.
- **Échec du certificat** : le domaine ne pointe pas vers le serveur ou le port 80 est fermé.

## Points d'attention

- Le script installe les paquets `docker.io` et `docker-compose` de la distribution. L'éditeur recommande Docker installé avec `get.docker.com` (étape 1).
- Le script clone `discourse_docker` dans `/var/discourse/discourse_docker` au lieu de `/var/discourse` : les commandes `./launcher` doivent alors être lancées depuis ce sous-dossier.

## Sources

- [Guide d'installation officiel](https://github.com/discourse/discourse/blob/main/docs/INSTALL-cloud.md)
- [Dépôt discourse_docker](https://github.com/discourse/discourse_docker)
