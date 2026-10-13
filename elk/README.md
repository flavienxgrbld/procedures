# Elastic Stack (ELK) — procédure d'installation

## Description

La suite Elastic, ou ELK, centralise et analyse les journaux. **Elasticsearch** stocke et indexe les données, **Logstash** et **Filebeat** les collectent et les transforment, **Kibana** les explore et les affiche dans des tableaux de bord. Cette procédure installe la suite sur un serveur Debian ou Ubuntu depuis le dépôt officiel d'Elastic.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu (dépôt APT Elastic) ; RHEL (dépôt YUM) |
| **Méthode** | Dépôt officiel `artifacts.elastic.co` |
| **Ports** | 9200 (Elasticsearch), 5601 (Kibana), 5044 (Logstash / Beats) |
| **Script** | `install_elk.sh` |

## Prérequis

- 4 Go de RAM au minimum (8 Go conseillés), 2 cœurs, 50 Go de disque.
- Un accès root et une connexion Internet.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/elk
sudo bash install_elk.sh
```

Le script installe la branche **7.x**. La procédure manuelle ci-dessous utilise la branche 8.x, actuelle, dont la sécurité est activée par défaut.

## Installation manuelle

### 1. Ajouter le dépôt Elastic

```bash
sudo apt update
sudo apt install -y apt-transport-https gnupg curl
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" \
  | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
sudo apt update
```

### 2. Installer Elasticsearch

```bash
sudo apt install -y elasticsearch
```

**Noter le mot de passe du compte `elastic`** affiché à la fin de l'installation. Pour le régénérer plus tard :

```bash
sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic
```

Pour que Kibana et les autres machines puissent joindre Elasticsearch, régler dans `/etc/elasticsearch/elasticsearch.yml` :

```yaml
network.host: 0.0.0.0
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now elasticsearch
```

### 3. Installer Kibana

```bash
sudo apt install -y kibana
```

Dans `/etc/kibana/kibana.yml` :

```yaml
server.host: "0.0.0.0"
```

Générer un jeton d'inscription, puis démarrer Kibana :

```bash
sudo /usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana
sudo systemctl enable --now kibana
```

Ouvrir `http://<adresse-du-serveur>:5601`, coller le jeton, puis saisir le code de vérification obtenu avec :

```bash
sudo /usr/share/kibana/bin/kibana-verification-code
```

Se connecter avec le compte `elastic`.

### 4. Installer Logstash et Filebeat (collecte)

```bash
sudo apt install -y logstash filebeat
sudo systemctl enable --now logstash
```

Filebeat s'installe plutôt sur les machines dont on veut collecter les journaux. Le configurer dans `/etc/filebeat/filebeat.yml` (sortie vers Elasticsearch ou Logstash), puis :

```bash
sudo filebeat modules enable system
sudo filebeat setup
sudo systemctl enable --now filebeat
```

### 5. Ouvrir les ports

```bash
sudo ufw allow 9200/tcp
sudo ufw allow 5601/tcp
sudo ufw allow 5044/tcp
```

## Vérification

```bash
systemctl status elasticsearch kibana
curl -k -u elastic https://localhost:9200
```

Elasticsearch répond avec le nom du cluster et sa version. Dans Kibana, *Discover* affiche les journaux envoyés par Filebeat.

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/elasticsearch/elasticsearch.yml` | Configuration d'Elasticsearch |
| `/etc/elasticsearch/jvm.options.d/` | Mémoire Java (`-Xms` / `-Xmx`) |
| `/etc/kibana/kibana.yml` | Configuration de Kibana |
| `/etc/logstash/conf.d/` | Pipelines Logstash |
| `/etc/filebeat/filebeat.yml` | Configuration de Filebeat |

## Dépannage

- Elasticsearch ne démarre pas faute de mémoire : limiter le tas Java dans `/etc/elasticsearch/jvm.options.d/heap.options` (`-Xms1g` et `-Xmx1g`).
- Journaux : `journalctl -u elasticsearch` et `/var/log/elasticsearch/`.

## Points d'attention

- Le script installe la branche 7.x, sans sécurité activée : Elasticsearch répond sans authentification sur le port 9200 dès que celui-ci est ouvert.
- Le script installe `openjdk-11-jre`, inutile : Elasticsearch et Logstash embarquent leur propre Java. Il utilise aussi `apt-key`, retiré des versions récentes de Debian et Ubuntu.
- Le script ouvre le port 5000 pour Logstash, alors que l'entrée Beats utilise le port 5044 par convention.

## Sources

- [Installer Elasticsearch (paquet Debian)](https://www.elastic.co/guide/en/elasticsearch/reference/current/deb.html)
- [Installer Kibana](https://www.elastic.co/guide/en/kibana/current/deb.html)
- [Démarrer avec Filebeat](https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-installation-configuration.html)
