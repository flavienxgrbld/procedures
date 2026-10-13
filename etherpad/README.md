# Etherpad — procédure d'installation

## Description

Etherpad est un éditeur de texte collaboratif en temps réel : plusieurs personnes écrivent dans le même document, chacune avec sa couleur, avec historique des versions et discussion intégrée. Cette procédure l'installe avec l'image Docker officielle, la méthode la plus simple à maintenir.

| | |
|---|---|
| **Systèmes** | Toute distribution avec Docker |
| **Méthode** | Image Docker officielle `etherpad/etherpad` (manuel) ; sources Node.js (script) |
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

Lire les points d'attention : en l'état, le script n'arrive pas à récupérer le code d'Etherpad.

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
    ports:
      - "9001:9001"
    environment:
      TITLE: "Etherpad du labo"
      ADMIN_PASSWORD: "MotDePasseFort"
      DEFAULT_PAD_TEXT: "Bienvenue sur ce pad."
    volumes:
      - etherpad_data:/opt/etherpad-lite/var

volumes:
  etherpad_data:
```

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

- Le script crée l'utilisateur `etherpad` avec son dossier personnel `/opt/etherpad`. Ce dossier n'est donc pas vide (fichiers `.bashrc`, `.profile`), et le `git clone ... .` qui suit échoue silencieusement (`|| true`). Le `npm install` suivant ne trouve aucun projet et arrête le script.
- Même avec le code présent, les fichiers appartiendraient à `root` alors que le service tourne sous `etherpad`, qui ne pourrait pas écrire ses données.
- La base par défaut d'Etherpad (`dirty.db`) est réservée aux tests. En production, configurer une base PostgreSQL ou MySQL (variables `DB_TYPE`, `DB_HOST`, etc.).
- Le message affiché par le script (« Crowdfunding ») ne correspond pas au service installé.

## Sources

- [Documentation Etherpad](https://docs.etherpad.org/)
- [Dépôt Etherpad](https://github.com/ether/etherpad)
