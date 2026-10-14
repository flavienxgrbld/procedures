# SeaweedFS — procédure d'installation

## Description

SeaweedFS est un système de stockage distribué libre (licence Apache 2.0), rapide pour un très grand nombre de fichiers. Il propose un système de fichiers (*filer*) et une **API compatible Amazon S3**, ce qui en fait une alternative libre à MinIO pour les sauvegardes et les applications qui parlent S3. Cette procédure installe un nœud unique regroupant tous les composants.

| | |
|---|---|
| **Systèmes** | Linux 64 bits avec systemd |
| **Méthode** | Binaire officiel `weed` (GitHub), version 4.48 |
| **Ports** | 9333 (master), 8080 (volume), 8888 (filer), 8333 (API S3) |
| **Script** | `install_seaweedfs.sh` |

## Prérequis

- Un disque ou une partition pour les données (ici `/var/lib/seaweedfs`).
- Un accès root et une connexion Internet.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/seaweedfs
sudo bash install_seaweedfs.sh
```

Lire les points d'attention : le script ne démarre que le maître, qui ne peut rien stocker seul.

## Installation manuelle

### 1. Installer le binaire

```bash
cd /tmp
wget https://github.com/seaweedfs/seaweedfs/releases/download/4.48/linux_amd64.tar.gz
tar -xzf linux_amd64.tar.gz
sudo mv weed /usr/local/bin/
weed version
```

### 2. Créer l'utilisateur et le dossier de données

```bash
sudo useradd -r -s /usr/sbin/nologin seaweedfs
sudo mkdir -p /var/lib/seaweedfs /etc/seaweedfs
sudo chown seaweedfs:seaweedfs /var/lib/seaweedfs
```

### 3. Définir les identifiants S3

`/etc/seaweedfs/s3.json` :

```json
{
  "identities": [
    {
      "name": "admin",
      "credentials": [{ "accessKey": "admin", "secretKey": "UneCleSecreteLongue" }],
      "actions": ["Admin", "Read", "Write", "List", "Tagging"]
    }
  ]
}
```

```bash
sudo chown root:seaweedfs /etc/seaweedfs/s3.json
sudo chmod 640 /etc/seaweedfs/s3.json
```

### 4. Créer le service (tous les composants sur un nœud)

`/etc/systemd/system/seaweedfs.service` :

```ini
[Unit]
Description=SeaweedFS
After=network.target

[Service]
User=seaweedfs
Group=seaweedfs
ExecStart=/usr/local/bin/weed server -dir=/var/lib/seaweedfs -ip=192.168.1.70 -filer -s3 -s3.config=/etc/seaweedfs/s3.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

Remplacer `192.168.1.70` par l'adresse du serveur.

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now seaweedfs
sudo ufw allow from 192.168.1.0/24 to any port 8333 proto tcp
```

### 5. Utiliser l'API S3

```bash
aws configure set aws_access_key_id admin
aws configure set aws_secret_access_key UneCleSecreteLongue
aws --endpoint-url http://192.168.1.70:8333 s3 mb s3://sauvegardes
aws --endpoint-url http://192.168.1.70:8333 s3 cp fichier.tar.gz s3://sauvegardes/
aws --endpoint-url http://192.168.1.70:8333 s3 ls s3://sauvegardes
```

## Vérification

```bash
systemctl status seaweedfs
curl -s http://localhost:9333/cluster/status
```

L'interface du maître (`http://<serveur>:9333`) affiche les volumes, et celle du filer (`http://<serveur>:8888`) les fichiers.

## Points d'attention

- Le script ne démarre que le **maître** (`weed master`), qui gère les métadonnées sans stocker de données : sans serveur de volumes, aucun fichier ne peut être enregistré. Il n'active ni le filer ni l'API S3.
- Il ne précise pas `-mdir` : le maître écrit ses métadonnées dans `/tmp`, effacé au redémarrage. Il écoute aussi sur `localhost`, ce qui le rend injoignable depuis le réseau.
- Il installe la version 3.57 ; la version actuelle est la 4.48.
- Exposée sans identifiants, l'API S3 accepte toutes les requêtes : toujours fournir `-s3.config`.

## Sources

- [Dépôt SeaweedFS](https://github.com/seaweedfs/seaweedfs)
- [API compatible S3](https://github.com/seaweedfs/seaweedfs/wiki/Amazon-S3-API)
