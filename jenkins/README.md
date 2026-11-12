# Jenkins — procédure d'installation

## Description

Jenkins est un serveur d'automatisation libre, très utilisé pour l'intégration et le déploiement continus (CI/CD) : il récupère le code, compile, teste et déploie à chaque modification, grâce à des pipelines et à des milliers d'extensions. Cette procédure installe la version LTS depuis le dépôt officiel.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu, RHEL/Fedora |
| **Méthode** | Dépôt officiel `pkg.jenkins.io` (version LTS) |
| **Ports** | 8080/tcp |
| **Script** | `install_jenkins.sh` |

## Prérequis

- Java 21 ou 25 (installé par le script ; voir l'étape 1).
- 2 Go de RAM au minimum, 10 Go de disque.
- Un accès root et une connexion Internet.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/jenkins
sudo bash install_jenkins.sh
```

Le script installe Java 21 (OpenJDK de la distribution, ou Eclipse Temurin sur Debian 12 qui n'a que Java 17), ajoute le dépôt Jenkins LTS avec la clé 2026, installe et démarre Jenkins, puis attend la création du mot de passe initial et l'affiche. Variable facultative : `JENKINS_PORT`.

## Installation manuelle

### 1. Installer Java

```bash
sudo apt update
sudo apt install -y fontconfig openjdk-21-jre-headless
java -version
```

Jenkins LTS demande Java 21 ou 25 depuis la version 2.555.1 (avril 2026). Debian 13 et Ubuntu 22.04/24.04 fournissent `openjdk-21-jre-headless`. Sur **Debian 12**, qui n'a que Java 17, installer Eclipse Temurin 21 :

```bash
sudo apt install -y wget gpg
wget -qO- https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo gpg --dearmor -o /etc/apt/keyrings/adoptium.gpg
echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb bookworm main" | sudo tee /etc/apt/sources.list.d/adoptium.list
sudo apt update && sudo apt install -y temurin-21-jre fontconfig
```

### 2. Ajouter le dépôt Jenkins

```bash
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  | sudo tee /etc/apt/sources.list.d/jenkins.list
sudo apt update
```

### 3. Installer et démarrer Jenkins

```bash
sudo apt install -y jenkins
sudo systemctl enable --now jenkins
sudo ufw allow 8080/tcp
```

### 4. Déverrouiller Jenkins

Récupérer le mot de passe initial :

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Ouvrir `http://<adresse-du-serveur>:8080`, coller ce mot de passe, puis :

1. choisir **Installer les plugins suggérés** ;
2. créer le compte administrateur ;
3. valider l'URL de Jenkins.

### 5. Créer un premier pipeline

*Nouvel item → Pipeline*, puis dans la section Pipeline :

```groovy
pipeline {
    agent any
    stages {
        stage('Test') {
            steps {
                sh 'echo "Jenkins fonctionne"'
                sh 'uname -a'
            }
        }
    }
}
```

## Vérification

```bash
systemctl status jenkins
curl -I http://localhost:8080/login
```

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/var/lib/jenkins/` | Données : tâches, plugins, configuration (`JENKINS_HOME`) |
| `/var/log/jenkins/` ou `journalctl -u jenkins` | Journaux |

## Dépannage

- **Jenkins ne démarre pas** : souvent une version de Java trop ancienne. Vérifier avec `journalctl -u jenkins -n 50`.
- Changer le port : `sudo systemctl edit jenkins`, puis ajouter `Environment="JENKINS_PORT=8081"` dans la section `[Service]`.

## Points d'attention

- Jenkins LTS 2.555.1 et suivantes exigent **Java 21 ou 25** : Java 17 n'est plus accepté. Sur Debian 12, OpenJDK 21 n'existe pas dans les dépôts : utiliser Eclipse Temurin (dépôt Adoptium), comme le script.
- La clé de signature du dépôt change régulièrement (clés 2023 puis 2026) : si `apt update` signale une signature invalide, reprendre la clé indiquée sur la page d'installation officielle.
- Les jobs s'exécutent sur le contrôleur avec l'utilisateur `jenkins` : pour des projets non maîtrisés, utiliser des agents séparés.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Installer Jenkins sur Linux](https://www.jenkins.io/doc/book/installing/linux/)
- [Prise en charge de Java](https://www.jenkins.io/doc/book/platform-information/support-policy-java/)
- [Jenkins — politique de prise en charge de Java](https://www.jenkins.io/doc/book/platform-information/support-policy-java/)
