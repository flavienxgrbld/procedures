# Certbot — procédure d'installation

## Description

Certbot obtient et renouvelle automatiquement des certificats TLS gratuits auprès de Let's Encrypt, pour passer un site en HTTPS. Cette procédure installe Certbot avec ses extensions Apache et Nginx et active le renouvellement automatique.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu, RHEL/Fedora, openSUSE, Arch |
| **Méthode** | Paquets de la distribution |
| **Ports** | 80/tcp accessible depuis Internet (validation HTTP-01) |
| **Script** | `install_certbot.sh` |

## Prérequis

- Un **nom de domaine public** dont l'enregistrement DNS (A ou AAAA) pointe vers le serveur.
- Le port 80 joignable depuis Internet (redirection de port sur la box si besoin).
- Un serveur web Apache ou Nginx déjà en place (voir les procédures `apache` et `nginx`), sauf en mode `--standalone`.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/certbot
sudo bash install_certbot.sh
```

## Installation manuelle

### 1. Installer Certbot et les extensions

```bash
sudo apt update
sudo apt install -y certbot python3-certbot-apache python3-certbot-nginx
certbot --version
```

### 2. Obtenir un certificat

Choisir la méthode qui correspond au serveur :

```bash
# Apache : obtient le certificat et configure le site en HTTPS
sudo certbot --apache -d exemple.fr -d www.exemple.fr

# Nginx : idem
sudo certbot --nginx -d exemple.fr

# Sans serveur web (Certbot écoute lui-même sur le port 80)
sudo certbot certonly --standalone -d exemple.fr
```

Certbot demande une adresse e-mail (alertes d'expiration) et l'acceptation des conditions d'utilisation, puis propose la redirection HTTP vers HTTPS.

### 3. Activer le renouvellement automatique

Les certificats Let's Encrypt durent 90 jours. Le paquet installe un timer systemd qui les renouvelle :

```bash
sudo systemctl enable --now certbot.timer
systemctl list-timers | grep certbot
```

### 4. Tester le renouvellement

```bash
sudo certbot renew --dry-run
```

## Vérification

```bash
sudo certbot certificates
curl -I https://exemple.fr
```

Le navigateur doit afficher le cadenas, avec un certificat émis par Let's Encrypt.

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/letsencrypt/live/<domaine>/fullchain.pem` | Certificat + chaîne |
| `/etc/letsencrypt/live/<domaine>/privkey.pem` | Clé privée |
| `/etc/letsencrypt/renewal/` | Paramètres de renouvellement |
| `/var/log/letsencrypt/letsencrypt.log` | Journal |

## Dépannage

- **Échec de validation** : le domaine ne pointe pas vers le serveur ou le port 80 est bloqué. Vérifier avec `dig +short exemple.fr` et depuis l'extérieur.
- **Too many requests** : Let's Encrypt limite le nombre de demandes. Faire les tests avec `--staging`.

## Points d'attention

- Let's Encrypt ne délivre pas de certificat pour un nom interne (`.local`, `.lan`) ou une adresse IP privée. Sur un réseau de TP, utiliser un certificat autosigné ou une autorité de certification interne.
- Le script fait un `upgrade` complet du système avant l'installation.

## Sources

- [Certbot — instructions officielles](https://certbot.eff.org/instructions)
- [Documentation Let's Encrypt](https://letsencrypt.org/fr/docs/)
