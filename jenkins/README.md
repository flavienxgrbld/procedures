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

- Java 17 ou 21 (OpenJDK).
- 2 Go de RAM au minimum, 10 Go de disque.
- Un accès root et une connexion Internet.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/jenkins
sudo bash install_jenkins.sh
```

Lire les points d'attention : le script utilise une clé de dépôt obsolète.

## Installation manuelle

### 1. Installer Java

```bash
sudo apt update
sudo apt install -y fontconfig openjdk-17-jre
java -version
```

Sur Debian 13 ou Ubuntu 24.04, `openjdk-21-jre` convient aussi.

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

- Le script importe `jenkins.io.key`, l'ancienne clé du dépôt, avec `apt-key` (retiré des distributions récentes). Les paquets actuels sont signés avec la clé 2026 (`jenkins.io-2026.key`) ; la clé 2023 a elle aussi expiré en mars 2026 : `apt update` refuse le dépôt.
- Le script installe `default-jre`, qui correspond à Java 11 sur Ubuntu 22.04 et Debian 11 : les versions actuelles de Jenkins demandent Java 17 et ne démarrent pas. Sur RHEL, il installe explicitement Java 11.
- Le script lit le mot de passe initial 10 secondes après le démarrage, alors que Jenkins peut mettre plus longtemps à créer le fichier : il s'arrête alors en erreur. Le mot de passe se récupère ensuite avec la commande de l'étape 4.

## Sources

- [Installer Jenkins sur Linux](https://www.jenkins.io/doc/book/installing/linux/)
- [Prise en charge de Java](https://www.jenkins.io/doc/book/platform-information/support-policy-java/)
