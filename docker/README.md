# Installation de Docker

## Description
Docker est une plateforme de conteneurisation open-source qui permet de créer, déployer et exécuter des applications dans des conteneurs isolés. Il facilite le développement, le test et le déploiement d'applications.

## Prérequis
- Système d'exploitation : Ubuntu/Debian, CentOS/RHEL, SUSE, Arch Linux
- Architecture : x86_64 (amd64)
- Accès : Root ou sudo
- Connexion Internet
- Noyau Linux version 3.10 ou supérieure

## Installation

### Méthode automatique (recommandée)
Exécutez le script d'installation fourni :

```bash
bash install_docker.sh
```

### Étapes détaillées manuelles

1. **Mise à jour du système**
   ```bash
   sudo apt update && sudo apt upgrade -y  # Ubuntu/Debian
   ```

2. **Installation de Docker**
   - Sur Ubuntu/Debian :
     ```bash
     sudo apt install apt-transport-https ca-certificates curl gnupg lsb-release -y
     curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
     echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
     sudo apt update
     sudo apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
     ```
   - Sur CentOS/RHEL :
     ```bash
     sudo yum install docker docker-compose -y
     ```
   - Sur SUSE :
     ```bash
     sudo zypper install docker docker-compose -y
     ```
   - Sur Arch Linux :
     ```bash
     sudo pacman -S docker docker-compose -y
     ```

3. **Activation et démarrage du service**
   ```bash
   sudo systemctl enable docker
   sudo systemctl start docker
   ```

4. **Ajout d'un utilisateur au groupe docker**
   ```bash
   sudo usermod -aG docker $USER
   ```
   *Note : Déconnectez-vous et reconnectez-vous pour que les changements prennent effet.*

## Configuration

### Démarrage automatique
Docker démarre automatiquement au boot du système.

### Configuration du démon Docker (optionnel)
Modifiez `/etc/docker/daemon.json` pour des configurations avancées :

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

Redémarrez Docker :
```bash
sudo systemctl restart docker
```

## Utilisation de base

- Vérifier l'installation :
  ```bash
  docker --version
  docker compose version
  ```

- Télécharger une image :
  ```bash
  docker pull hello-world
  ```

- Exécuter un conteneur :
  ```bash
  docker run hello-world
  ```

- Lister les conteneurs :
  ```bash
  docker ps -a
  ```

- Utiliser Docker Compose :
  Créez un fichier `docker-compose.yml` et exécutez :
  ```bash
  docker compose up -d
  ```

## Vérification

- Vérifiez que le service est actif : `sudo systemctl status docker`
- Testez avec : `docker run hello-world`
- Vérifiez les logs : `sudo journalctl -u docker`

## Dépannage

- Problèmes de permissions : Assurez-vous d'être dans le groupe docker
- Erreurs de réseau : Vérifiez la configuration du proxy si nécessaire
- Espace disque : `docker system df` pour voir l'utilisation

## Sécurité

- Évitez d'exécuter des conteneurs en tant que root
- Utilisez des images officielles
- Scannez les images pour les vulnérabilités

## Documentation
- [Site officiel de Docker](https://www.docker.com/)
- [Documentation](https://docs.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)

## Notes
- Docker simplifie le déploiement d'applications multi-conteneurs.
- Pensez à nettoyer régulièrement les images et conteneurs inutilisés : `docker system prune`
- Pour la production, considérez Docker Swarm ou Kubernetes.
