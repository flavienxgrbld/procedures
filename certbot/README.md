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

Installer d'abord le serveur web (Apache ou Nginx) : le script installe seulement l'extension Certbot qui lui correspond, ou aucune extension (mode `standalone`) s'il n'y a pas de serveur web.

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/certbot
sudo bash install_certbot.sh
```

Il active ensuite le minuteur de renouvellement fourni par le paquet (`certbot.timer` sur Debian/Ubuntu, `certbot-renew.timer` sur Fedora/RHEL), ou une tâche cron à défaut.

Pour obtenir directement un certificat, indiquer le domaine et une adresse de contact :

```bash
sudo CERTBOT_DOMAIN=www.exemple.fr CERTBOT_EMAIL=admin@exemple.fr bash install_certbot.sh
```

Avec Apache ou Nginx, le site est alors configuré en HTTPS avec redirection depuis HTTP, puis le renouvellement est testé (`certbot renew --dry-run`).

## Installation manuelle

### 1. Installer Certbot et l'extension du serveur web

N'installer que l'extension du serveur présent : `python3-certbot-apache` dépend d'Apache et `python3-certbot-nginx` de Nginx, installer les deux ajouterait un second serveur web.

```bash
sudo apt update
sudo apt install -y certbot python3-certbot-apache   # serveur Apache
# ou : sudo apt install -y certbot python3-certbot-nginx   # serveur Nginx
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

- Let's Encrypt ne délivre pas de certificat pour un nom interne (`.local`, `.lan`) ou une adresse IP privée : le domaine doit être public et le port 80 joignable depuis Internet. Sur un réseau de TP, utiliser un certificat autosigné ou une autorité de certification interne.
- Sur RHEL, Rocky ou AlmaLinux, Certbot vient du dépôt EPEL, que le script installe.
- Le certificat d'un domaine expire au bout de 90 jours : vérifier de temps en temps `sudo certbot renew --dry-run`.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Certbot — instructions officielles](https://certbot.eff.org/instructions)
- [Documentation Let's Encrypt](https://letsencrypt.org/fr/docs/)
