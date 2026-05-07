# Installation de ELK (Elastic Stack)

## Description
ELK (Elasticsearch, Logstash, Kibana) est une suite open source utilisée pour la collecte, l’analyse et la visualisation de logs et de données.

### Type
Stack de monitoring et analytics

## Prérequis

- **Système d'exploitation** : Ubuntu 20.04 LTS ou plus récent / Debian 11+ / CentOS 8+ / Fedora / openSUSE / Arch Linux
- **Accès** : root ou sudo
- **Ressources** : minimum 4 Go de RAM recommandé (ELK est gourmand)
- **Réseau** : connexion Internet stable
- **Ports** :
  - 5601 (Kibana)
  - 9200 (Elasticsearch)
  - 5044 (Logstash)
- **Dépendances** : curl, wget, Java (OpenJDK 11+)

## Installation

### Méthode automatique (recommandée)

```bash
# 1. Rendre le script exécutable
chmod +x install_elk.sh

# 2. Lancer l'installation
bash install_elk.sh

# 3. Suivre les instructions
```

### Installation manuelle (étapes détaillées)

#### 1. Mise à jour du système
```bash
sudo apt update && sudo apt upgrade -y
```

#### 2. Installation de Java (obligatoire)
```bash
sudo apt install openjdk-11-jdk -y
java -version
```

#### 3. Ajout du dépôt Elastic
```bash
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

sudo apt install apt-transport-https -y

echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-8.x.list

sudo apt update
```

#### 4. Installation des composants

```bash
sudo apt install elasticsearch logstash kibana -y
```

#### 5. Activation des services

```bash
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch

sudo systemctl enable logstash
sudo systemctl start logstash

sudo systemctl enable kibana
sudo systemctl start kibana
```

## Configuration

### Elasticsearch
Fichier :
```bash
/etc/elasticsearch/elasticsearch.yml
```

### Kibana
Fichier :
```bash
/etc/kibana/kibana.yml
```

Accès :
```
http://localhost:5601
```

### Logstash
Fichiers :
```
/etc/logstash/conf.d/
```

## Vérification de l'installation

```bash
# Statut Elasticsearch
systemctl status elasticsearch

# Statut Kibana
systemctl status kibana

# Statut Logstash
systemctl status logstash
```

### Vérifier les ports

```bash
ss -tlnp | grep 9200
ss -tlnp | grep 5601
ss -tlnp | grep 5044
```

### Test Elasticsearch

```bash
curl http://localhost:9200
```

## Configuration firewall

### UFW
```bash
sudo ufw allow 5601/tcp
sudo ufw allow 9200/tcp
sudo ufw allow 5044/tcp
```

### firewall-cmd
```bash
sudo firewall-cmd --permanent --add-port=5601/tcp
sudo firewall-cmd --permanent --add-port=9200/tcp
sudo firewall-cmd --permanent --add-port=5044/tcp
sudo firewall-cmd --reload
```

## Dépannage

```bash
# Logs Elasticsearch
journalctl -u elasticsearch -f

# Logs Kibana
journalctl -u kibana -f

# Logs Logstash
journalctl -u logstash -f

# Vérifier Java
java -version
```

## Accès Web

- Kibana :
```
http://IP_DU_SERVEUR:5601
```

## Documentation
- https://www.elastic.co/
- https://www.elastic.co/guide/

## Notes
- ELK est très gourmand en ressources (RAM et CPU)
- Elasticsearch doit être correctement dimensionné pour la production
- Il est recommandé d’utiliser HTTPS en production
- Peut être remplacé ou complété par Grafana/Loki dans certains cas