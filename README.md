# 📚 Procédures d'Installation

Ce dépôt contient des scripts d'installation automatisés et de la documentation pour diverses solutions de gestion IT.

## 🚀 Contenu

### GLPI 11.0.4
Solution complète de gestion de parc informatique et de service desk.

- 📁 **Emplacement** : [`GLPI/`](GLPI/)
- 🔧 **Script d'installation** : [install_glpi.sh](GLPI/install_glpi.sh)
- 📖 **Documentation** : [installation glpi.md](GLPI/installation%20glpi.md)
- 💻 **OS supportés** : Ubuntu 22.04 LTS (Jammy), Debian 11/12
- 🐘 **Prérequis** : PHP 8.2+, Apache2, MariaDB

**Fonctionnalités** :
- Installation automatisée complète de GLPI
- Configuration du dépôt PHP Ondřej (PPA pour Ubuntu)
- Création de la base de données et utilisateur MySQL
- Configuration des répertoires sécurisés (`/etc/glpi`, `/var/lib/glpi`, `/var/log/glpi`)
- Configuration Apache avec VirtualHost
- Optimisation des paramètres PHP

**Utilisation rapide** :
```bash
cd GLPI
sudo chmod +x install_glpi.sh
sudo ./install_glpi.sh
```

---

### Zabbix 7.4
Solution de monitoring et supervision réseau open-source.

- 📁 **Emplacement** : [`ZABBIX/`](ZABBIX/)
- 🔧 **Script d'installation** : [install_zabbix.sh](ZABBIX/install_zabbix.sh)
- 📖 **Documentation** : [installation zabbix.md](ZABBIX/installation%20zabbix.md)
- 💻 **OS supporté** : Debian 13
- 🐘 **Prérequis** : PHP, Apache2/Nginx, PostgreSQL/MySQL

**Utilisation rapide** :
```bash
cd ZABBIX
sudo chmod +x install_zabbix.sh
sudo ./install_zabbix.sh
```

---

## ⚙️ Prérequis Généraux

- Système d'exploitation à jour
- Accès root ou sudo
- Connexion internet active
- Minimum 2 Go de RAM (4 Go recommandés)
- 10 Go d'espace disque disponible

## 📋 Instructions d'Utilisation

1. **Cloner le dépôt** :
   ```bash
   git clone https://github.com/flavienxgrbld/procedures.git
   cd procedures
   ```

2. **Naviguer vers la solution souhaitée** :
   ```bash
   cd GLPI  # ou ZABBIX
   ```

3. **Rendre le script exécutable** :
   ```bash
   chmod +x install_*.sh
   ```

4. **Exécuter le script en tant que root** :
   ```bash
   sudo ./install_*.sh
   ```

5. **Suivre les instructions** affichées à l'écran

## ⚠️ Notes Importantes

- **Sauvegarde** : Toujours sauvegarder vos données avant d'exécuter un script d'installation
- **Test** : Testez d'abord dans un environnement de développement/test
- **Sécurité** : Changez tous les mots de passe par défaut après installation
- **Documentation** : Consultez la documentation spécifique dans chaque dossier pour plus de détails

## 🔒 Sécurité

Les scripts effectuent les opérations suivantes pour la sécurité :
- Configuration de `mysql_secure_installation`
- Permissions restrictives sur les fichiers et répertoires
- Séparation des répertoires de configuration
- Activation de `session.cookie_httponly` pour PHP

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :
- Signaler des bugs
- Proposer des améliorations
- Ajouter de nouvelles procédures

## 📝 Licence

Ces scripts et documentations sont fournis "tels quels" à des fins éducatives et de déploiement.

## 👤 Auteur

**flavienxgrbld**

---

*Dernière mise à jour : Janvier 2026*
*tout droits réservé*
