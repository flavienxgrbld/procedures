# Keycloak — procédure d'installation

## Description

Keycloak est un serveur libre de gestion des identités et des accès : authentification unique (SSO) entre applications, protocoles OpenID Connect et SAML, fédération avec un annuaire LDAP ou Active Directory, double authentification. Cette procédure installe Keycloak 26 avec le conteneur officiel, qui embarque la bonne version de Java.

| | |
|---|---|
| **Systèmes** | Toute distribution avec Docker |
| **Méthode** | Image officielle `quay.io/keycloak/keycloak` |
| **Ports** | 8080/tcp (HTTP), 8443/tcp (HTTPS en production) |
| **Script** | `install_keycloak.sh` |

## Prérequis

- Docker installé (voir la procédure `docker`).
- 2 Go de RAM au minimum.
- En production : un nom de domaine, un certificat TLS et une base PostgreSQL.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/keycloak
sudo bash install_keycloak.sh
sudo systemctl start keycloak
```

Lire les points d'attention : le service créé par le script ne démarre pas.

## Installation manuelle

### 1. Démarrer Keycloak en mode développement (labo)

```bash
sudo docker run -d --name keycloak --restart unless-stopped \
  -p 8080:8080 \
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
  -e KC_BOOTSTRAP_ADMIN_PASSWORD=MotDePasseFort \
  quay.io/keycloak/keycloak:26.8.1 start-dev
sudo ufw allow 8080/tcp
```

Le mode `start-dev` accepte HTTP et une base interne : il convient pour apprendre et tester, pas pour la production.

### 2. Se connecter à la console d'administration

Ouvrir `http://<adresse-du-serveur>:8080/admin` et se connecter avec le compte `admin`. Ce compte bootstrap est temporaire : créer un vrai compte administrateur dans le royaume `master`, puis supprimer `admin`.

### 3. Créer un royaume et un utilisateur

1. Menu des royaumes → **Create realm** → nom `labo`.
2. **Users → Add user** : renseigner l'identifiant, puis dans l'onglet *Credentials*, définir un mot de passe (*Temporary* désactivé).
3. Tester la connexion sur `http://<adresse-du-serveur>:8080/realms/labo/account`.

### 4. Déclarer une application (client OIDC)

**Clients → Create client** : type *OpenID Connect*, identifiant de l'application, puis l'URL de redirection valide (*Valid redirect URIs*). L'application utilise ensuite l'émetteur `http://<serveur>:8080/realms/labo`.

## Mode production

En production, Keycloak doit utiliser HTTPS, un nom d'hôte fixe et une base externe. Avec Docker Compose et PostgreSQL :

```yaml
services:
  postgres:
    image: postgres:17
    restart: unless-stopped
    environment:
      POSTGRES_DB: keycloak
      POSTGRES_USER: keycloak
      POSTGRES_PASSWORD: MotDePasseBase
    volumes:
      - pg_data:/var/lib/postgresql/data

  keycloak:
    image: quay.io/keycloak/keycloak:26.8.1
    restart: unless-stopped
    command: start
    depends_on: [postgres]
    ports:
      - "8443:8443"
    environment:
      KC_DB: postgres
      KC_DB_URL: jdbc:postgresql://postgres:5432/keycloak
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD: MotDePasseBase
      KC_HOSTNAME: https://sso.exemple.fr:8443
      KC_HTTPS_CERTIFICATE_FILE: /certs/fullchain.pem
      KC_HTTPS_CERTIFICATE_KEY_FILE: /certs/privkey.pem
      KC_BOOTSTRAP_ADMIN_USERNAME: admin
      KC_BOOTSTRAP_ADMIN_PASSWORD: MotDePasseFort
    volumes:
      - ./certs:/certs:ro

volumes:
  pg_data:
```

## Vérification

```bash
sudo docker logs keycloak | tail -20
curl -s http://localhost:8080/realms/master/.well-known/openid-configuration | head -c 200
```

## Dépannage

- **« HTTPS required »** en se connectant depuis un autre poste : normal hors `start-dev`. Utiliser HTTPS, ou, pour un labo uniquement, désactiver l'exigence sur le royaume (*Realm settings → General → Require SSL : none*).
- Journaux : `sudo docker logs -f keycloak`.

## Points d'attention

- Le service du script lance `kc.sh start` (mode production) sans certificat TLS ni option `--http-enabled=true` : Keycloak refuse de démarrer. Il fixe aussi `--hostname=localhost`, ce qui empêche l'accès depuis une autre machine.
- Le script ne crée aucun compte administrateur et ne démarre pas le service (seulement `enable`).
- Il installe Keycloak 23.0.1, qui ne reçoit plus de correctifs de sécurité. Keycloak 26.8 demande OpenJDK 25 pour une installation hors conteneur.

## Sources

- [Démarrer Keycloak avec Docker](https://www.keycloak.org/getting-started/getting-started-docker)
- [Configurer le nom d'hôte](https://www.keycloak.org/server/hostname)
- [Mise en production](https://www.keycloak.org/server/configuration-production)
