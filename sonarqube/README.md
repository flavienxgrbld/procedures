# SonarQube — procédure d'installation

## Description

SonarQube analyse le code source pour détecter bogues, vulnérabilités, failles de sécurité et « mauvaises odeurs » (*code smells*), et suit la couverture de tests. Il s'intègre aux pipelines CI/CD (Jenkins, GitLab CI) et applique des seuils de qualité (*Quality Gates*). Cette procédure installe SonarQube Community Build avec Docker et PostgreSQL.

| | |
|---|---|
| **Systèmes** | Linux 64 bits avec Docker |
| **Méthode** | Image officielle `sonarqube:community` + PostgreSQL |
| **Dossier** | `/opt/sonarqube` |
| **Ports** | 9000/tcp |
| **Script** | `install_sonarqube.sh` |

## Prérequis

- Docker et Docker Compose (procédure `docker`).
- 4 Go de RAM au minimum (Elasticsearch embarqué).
- Les réglages noyau exigés par Elasticsearch (étape 1).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/sonarqube
sudo bash install_sonarqube.sh
```

Lire les points d'attention : le script s'arrête dès l'étape de la base de données.

## Installation manuelle

### 1. Régler le noyau

```bash
echo 'vm.max_map_count=524288' | sudo tee /etc/sysctl.d/99-sonarqube.conf
echo 'fs.file-max=131072' | sudo tee -a /etc/sysctl.d/99-sonarqube.conf
sudo sysctl --system
```

### 2. Décrire les services

```bash
sudo mkdir -p /opt/sonarqube
cd /opt/sonarqube
```

`/opt/sonarqube/compose.yaml` :

```yaml
services:
  sonarqube:
    image: sonarqube:community
    restart: unless-stopped
    depends_on: [db]
    ports:
      - "9000:9000"
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://db:5432/sonar
      SONAR_JDBC_USERNAME: sonar
      SONAR_JDBC_PASSWORD: MotDePasseBase
    volumes:
      - sonar_data:/opt/sonarqube/data
      - sonar_extensions:/opt/sonarqube/extensions
      - sonar_logs:/opt/sonarqube/logs

  db:
    image: postgres:17
    restart: unless-stopped
    environment:
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: MotDePasseBase
      POSTGRES_DB: sonar
    volumes:
      - pg_data:/var/lib/postgresql/data

volumes:
  sonar_data:
  sonar_extensions:
  sonar_logs:
  pg_data:
```

### 3. Démarrer

```bash
sudo docker compose up -d
sudo ufw allow from 192.168.1.0/24 to any port 9000 proto tcp
```

Le premier démarrage prend une à deux minutes.

### 4. Première connexion

Ouvrir `http://<adresse-du-serveur>:9000` avec `admin` / `admin` : SonarQube impose de changer le mot de passe.

### 5. Analyser un projet

*Create Project → Manually*, puis générer un jeton d'analyse. Depuis le dossier du projet, avec le scanner en conteneur :

```bash
docker run --rm -v "$PWD:/usr/src" \
  -e SONAR_HOST_URL=http://<adresse-du-serveur>:9000 \
  -e SONAR_TOKEN=<jeton> \
  sonarsource/sonar-scanner-cli -Dsonar.projectKey=mon-projet
```

## Vérification

```bash
sudo docker compose ps
curl -s http://localhost:9000/api/system/status
```

L'API doit répondre `"status":"UP"`.

## Points d'attention

- Le script exécute `. "$SCRIPT_DIR/../databases/install_postgresql.sh"`, mais la variable `SCRIPT_DIR` n'est jamais définie : avec `set -u`, le script s'arrête sur « unbound variable » (le repli `|| pkg_install` n'est pas atteint). Le chemin indiqué n'existe pas non plus dans le dépôt.
- Il installe Java 11, alors que les versions actuelles de SonarQube demandent Java 17 ou 21. Il ne crée ni la base ni l'utilisateur PostgreSQL `sonarqube` déclarés dans sa configuration, et ne règle pas `vm.max_map_count` : Elasticsearch refuse de démarrer.

## Sources

- [Installer SonarQube Server](https://docs.sonarsource.com/sonarqube-server/latest/setup-and-upgrade/install-the-server/introduction/)
- [Image Docker SonarQube](https://hub.docker.com/_/sonarqube)
