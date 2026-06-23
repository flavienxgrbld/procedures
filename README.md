# procedures

Recueil de procédures d'installation pour une centaine de services self-hosted (monitoring, CI/CD, collaboration, stockage, ERP, sécurité, etc.). Chaque service dispose de son propre script d'installation et de sa documentation associée.

## Structure du dépôt

Chaque service possède son propre dossier à la racine, organisé de façon identique :

```
<nom_du_service>/
├── install_<nom_du_service>.sh   # Script d'installation
└── README.md                      # Documentation spécifique au service
```

Exemple :

```
wallabag/
├── install_wallabag.sh
└── README.md
```

## Philosophie

- **Standalone** : chaque script est indépendant et peut être exécuté seul, sans dépendre des autres dossiers du dépôt.
- **Un service = un dossier** : pas de procédure partagée entre plusieurs services, pas de fichier de variables commun.
- **Environnement variable** : l'OS et les prérequis (Linux Debian/Ubuntu, Docker, etc.) dépendent de chaque service — se référer au README de chaque dossier pour les prérequis exacts.

## Utilisation

1. Se rendre dans le dossier du service voulu :
   ```bash
   cd <nom_du_service>
   ```
2. Lire le `README.md` du dossier pour connaître les prérequis et variables à adapter avant exécution.
3. Rendre le script exécutable puis le lancer :
   ```bash
   chmod +x install_<nom_du_service>.sh
   ./install_<nom_du_service>.sh
   ```

## Avertissement

Ces scripts sont fournis tels quels, à but de documentation et de réutilisation personnelle. Avant toute exécution en production :
- relire le script pour comprendre ce qu'il fait,
- l'exécuter dans un environnement de test si possible,
- vérifier les prérequis (OS, ports, dépendances) indiqués dans le README du service concerné.

Aucune garantie n'est fournie quant à la compatibilité avec toutes les versions d'OS ou de dépendances.

## Liste des services couverts

<details>
<summary>Cliquer pour afficher la liste complète (103 services)</summary>

akaunting, alertmanager, apache, backblaze_sync, bacula, cacti, certbot, discourse, dnsmasq, docker, dokuwiki, dolibarr, drupal, duplicati, elk, emby, erpnext, etherpad, fail2ban, filebrowser, focalboard, ghost, gitea_self_hosted, gitlab_runner, gitlist, gitpod, GLPI, guacamole, haproxy, hashicorp_consul, hashicorp_nomad, home_assistant, hurl, hyperledger_fabric, immich, influxdb, invoice_ninja, jellyfin, jenkins, jitsi_meet, keycloak, kodi, landscape, localstack, loki, luajit, lxd, mastodon, MATOMO, matrix_synapse, mattermost_enhanced, mediawiki, meilisearch, minio, mongodb, moodle, mosquitto, netdata, nextcloud_talk, nginx, nginx_ui, node_red, ntopng, odoo, OPEN WEB ANALYTICS, openhab, openvpn, openwrt, outline, owncloud, paperless_ngx, penpot, pihole, PLAUSIBLE, plex, portainer, postgresql, prometheus, PROXMOX, rclone, redis, requestbin, restic, rocketchat, rustdesk, rustlings, seafile, seaweedfs, sentry, sonarqube, strapi, syncthing, taiga, tig_stack, typesense, uptime_kuma, vault, vaultwarden, wallabag, wireguard, woodpecker_ci, ZABBIX, zulip

</details>

## Signaler un problème

Si un script échoue ou qu'une étape de la documentation est incorrecte ou obsolète, merci d'ouvrir une **issue** sur le dépôt en précisant :
- le nom du service concerné,
- le message d'erreur ou le comportement observé,
- l'OS/environnement utilisé.

Les problèmes signalés seront traités dans les plus brefs délais.

## Contribuer

Pour ajouter un nouveau service, créer un dossier à la racine suivant la même convention de nommage (`install_<service>.sh` + `README.md`), en documentant clairement les prérequis et étapes de configuration dans le README du service.

## Licence

À définir selon vos préférences (MIT, GPL, etc.).