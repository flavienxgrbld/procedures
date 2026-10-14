# MinIO (stockage objet S3) — procédure

## Description

MinIO était le stockage objet compatible Amazon S3 le plus utilisé en auto-hébergement. Son édition open source n'est plus distribuée : le dépôt est archivé et les binaires publics ont été retirés. Cette procédure explique la situation et met en place un stockage S3 équivalent : l'édition gratuite AIStor de MinIO, ou SeaweedFS, entièrement libre.

| | |
|---|---|
| **Systèmes** | Linux 64 bits |
| **Méthode** | AIStor Free (MinIO) ou SeaweedFS (procédure `seaweedfs`) |
| **Ports** | 9000/tcp (API S3), 9001/tcp (console) |
| **Script** | `install_minio.sh` (voir les points d'attention) |

## Prérequis

- Un disque ou une partition dédiée aux données (ici monté sur `/srv/s3`).
- Un accès root et une connexion Internet.

## Option 1 : AIStor Free (MinIO)

AIStor Free est l'édition gratuite et autonome publiée par MinIO, sous licence propriétaire gratuite.

1. Télécharger le paquet AIStor depuis `https://min.io/download` (inscription demandée) et récupérer la clé de licence gratuite.
2. Installer le paquet `.deb` fourni :

```bash
sudo apt install -y ./minio_*_amd64.deb
```

3. Définir les identifiants et le stockage dans `/etc/default/minio` :

```bash
MINIO_ROOT_USER=admin
MINIO_ROOT_PASSWORD=MotDePasseFortDe8CaracteresMin
MINIO_VOLUMES="/srv/s3"
MINIO_OPTS="--console-address :9001"
```

4. Démarrer :

```bash
sudo systemctl enable --now minio
sudo ufw allow 9000/tcp
sudo ufw allow 9001/tcp
```

La console est accessible sur `http://<adresse-du-serveur>:9001`. Les noms du paquet et des variables peuvent varier selon la version d'AIStor : suivre sa documentation, notamment pour l'enregistrement de la licence.

## Option 2 : SeaweedFS (libre)

SeaweedFS fournit une API compatible S3 sous licence Apache 2.0. Voir la procédure [`seaweedfs`](../seaweedfs/README.md) du dépôt.

## Utiliser le stockage S3

Avec le client `mc` (MinIO) ou `aws` :

```bash
aws configure set aws_access_key_id admin
aws configure set aws_secret_access_key MotDePasseFortDe8CaracteresMin
aws --endpoint-url http://<adresse-du-serveur>:9000 s3 mb s3://sauvegardes
aws --endpoint-url http://<adresse-du-serveur>:9000 s3 cp fichier.tar.gz s3://sauvegardes/
```

## Vérification

```bash
curl -I http://localhost:9000/minio/health/live
```

## Points d'attention

- Le script télécharge `https://dl.min.io/server/minio/release/linux-amd64/minio`, qui renvoie « 410 Gone » (vérifié le 13/10/2026) : le binaire open source n'est plus publié et le script s'arrête au téléchargement.
- Même avec le binaire, le service du script ne définit ni `MINIO_ROOT_USER` ni `MINIO_ROOT_PASSWORD` : l'accès se fait avec le couple par défaut `minioadmin` / `minioadmin`. Sans `--console-address`, la console écoute aussi sur un port aléatoire, et non sur le port 9001 ouvert par le script.
- Un ancien binaire MinIO déjà installé continue de fonctionner, mais ne reçoit plus de correctifs de sécurité.

## Sources

- [Annonce et éditions MinIO](https://github.com/minio/minio)
- [Téléchargement AIStor](https://min.io/download)
