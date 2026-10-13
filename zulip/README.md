# Zulip — procédure d'installation

## Description

Zulip est une messagerie d'équipe libre, organisée en fils de discussion par sujet (*topics*) : chaque conversation reste lisible même avec beaucoup de messages et d'interlocuteurs. Cette procédure installe un serveur Zulip avec l'installateur officiel, qui configure lui-même PostgreSQL, Nginx, RabbitMQ et le certificat HTTPS.

| | |
|---|---|
| **Systèmes** | Ubuntu 22.04 / 24.04, Debian 12 / 13 (serveur dédié) |
| **Méthode** | Archive officielle `download.zulip.com` + script `scripts/setup/install` |
| **Ports** | 80/tcp et 443/tcp |
| **Script** | `install_zulip.sh` |

## Prérequis

- Une machine **dédiée** (l'installateur configure Nginx, PostgreSQL et d'autres services) avec 2 Go de RAM au minimum (4 Go conseillés) et 10 Go de disque.
- Un **nom de domaine** (ici `chat.exemple.fr`) pointant vers le serveur, ports 80 et 443 accessibles.
- Un serveur SMTP pour les invitations et notifications par e-mail.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/zulip
sudo bash install_zulip.sh
```

Lire les points d'attention : l'adresse utilisée par le script n'existe pas.

## Installation manuelle

### 1. Télécharger la dernière version

```bash
cd /tmp
curl -fLO https://download.zulip.com/server/zulip-server-latest.tar.gz
tar -xf zulip-server-latest.tar.gz
```

### 2. Lancer l'installateur

```bash
sudo ./zulip-server-*/scripts/setup/install --certbot \
  --email=admin@exemple.fr --hostname=chat.exemple.fr
```

L'option `--certbot` obtient automatiquement un certificat Let's Encrypt. Pour un labo sans domaine public, remplacer `--certbot` par `--self-signed-cert`. L'installation prend de 10 à 20 minutes.

### 3. Configurer l'envoi d'e-mails

Dans `/etc/zulip/settings.py` : `EMAIL_HOST`, `EMAIL_HOST_USER`, `EMAIL_PORT`, `EMAIL_USE_TLS`, puis le mot de passe dans `/etc/zulip/zulip-secrets.conf` (`email_password = ...`).

```bash
sudo -u zulip /home/zulip/deployments/current/scripts/restart-server
sudo -u zulip /home/zulip/deployments/current/manage.py send_test_email admin@exemple.fr
```

### 4. Créer l'organisation

À la fin de l'installation, l'installateur affiche un lien unique de création d'organisation. Pour en générer un nouveau :

```bash
sudo -u zulip /home/zulip/deployments/current/manage.py generate_realm_creation_link
```

Ouvrir ce lien pour créer l'organisation et le compte du propriétaire.

## Vérification

```bash
sudo -u zulip /home/zulip/deployments/current/scripts/restart-server
sudo supervisorctl status
```

Se connecter sur `https://chat.exemple.fr`, créer un canal et envoyer un message depuis l'application de bureau ou mobile.

## Mise à jour

```bash
sudo /home/zulip/deployments/current/scripts/upgrade-zulip zulip-server-latest.tar.gz
```

## Points d'attention

- Le script télécharge `https://zulip.com/deployments/next/install`, qui n'existe pas (erreur 404, vérifié le 13/10/2026), et l'exécute avec `bash -x` : l'installation ne peut pas aboutir.
- Il ne transmet ni `--hostname` ni `--email`, obligatoires pour l'installateur officiel.
- Zulip doit avoir sa propre machine ou VM : l'installateur remplace la configuration de Nginx et de PostgreSQL.

## Sources

- [Installer un serveur Zulip](https://zulip.readthedocs.io/en/stable/production/install.html)
- [Configuration des e-mails](https://zulip.readthedocs.io/en/stable/production/email.html)
