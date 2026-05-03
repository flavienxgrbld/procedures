# Installation d'Akaunting

## Description
Akaunting est un logiciel de comptabilité open-source gratuit qui permet de gérer les finances d'une entreprise. Il offre des fonctionnalités telles que la facturation, les dépenses, les rapports financiers, etc.

## Prérequis
- Système d'exploitation : Ubuntu/Debian Linux (ou autres distributions supportées)
- Accès : Root ou sudo
- Connexion Internet pour télécharger les dépendances
- Espace disque : Au moins 1 Go d'espace libre
- Mémoire : Au moins 512 Mo de RAM

## Installation

### Méthode automatique (recommandée)
Exécutez le script d'installation fourni :

```bash
bash install_akaunting.sh
```

### Étapes détaillées manuelles
Si vous préférez installer manuellement, suivez ces étapes :

1. **Mise à jour du système**
   ```bash
   sudo apt update && sudo apt upgrade -y  # Pour Ubuntu/Debian
   ```

2. **Installation de PHP 8.1**
   ```bash
   sudo apt install php8.1 php8.1-cli php8.1-common php8.1-curl php8.1-xml php8.1-zip -y
   ```

3. **Installation du serveur web Apache**
   ```bash
   sudo apt install apache2 -y
   sudo systemctl enable apache2
   sudo systemctl start apache2
   ```

4. **Installation de la base de données (MySQL/MariaDB)**
   ```bash
   sudo apt install mysql-server -y
   sudo systemctl enable mysql
   sudo systemctl start mysql
   ```

5. **Installation des modules PHP supplémentaires**
   ```bash
   sudo apt install php8.1-curl php8.1-xml php8.1-zip -y
   ```

6. **Installation de Composer**
   ```bash
   curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
   ```

7. **Téléchargement d'Akaunting**
   ```bash
   cd /var/www
   sudo git clone https://github.com/akaunting/akaunting.git
   cd akaunting
   ```

8. **Installation des dépendances PHP**
   ```bash
   composer install --no-dev
   ```

9. **Configuration**
   ```bash
   php artisan storage:link
   php artisan migrate --force
   ```

10. **Permissions**
    ```bash
    sudo chown -R www-data:www-data /var/www/akaunting
    ```

## Configuration

Après l'installation, configurez Akaunting via l'interface web :

1. Accédez à `http://votre-serveur/akaunting`
2. Suivez l'assistant d'installation pour configurer la base de données, créer un compte administrateur, etc.

### Configuration Apache (si nécessaire)
Créez un fichier de configuration pour le site :

```bash
sudo nano /etc/apache2/sites-available/akaunting.conf
```

Contenu :
```
<VirtualHost *:80>
    ServerName votre-domaine.com
    DocumentRoot /var/www/akaunting/public

    <Directory /var/www/akaunting/public>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

Activez le site :
```bash
sudo a2ensite akaunting.conf
sudo systemctl reload apache2
```

## Vérification

- Vérifiez que Apache est actif : `sudo systemctl status apache2`
- Vérifiez que MySQL est actif : `sudo systemctl status mysql`
- Accédez à l'application via le navigateur
- Testez la création d'une facture ou d'une dépense

## Dépannage

- Si des erreurs PHP apparaissent, vérifiez les logs : `sudo tail -f /var/log/apache2/error.log`
- Assurez-vous que les modules PHP sont chargés : `php -m`
- Pour les problèmes de base de données, vérifiez la configuration dans `.env`

## Documentation
- [Site officiel d'Akaunting](https://akaunting.com/)
- [Documentation](https://akaunting.com/docs)
- [GitHub](https://github.com/akaunting/akaunting)

## Notes
- Akaunting est compatible avec plusieurs langues et devises.
- Pensez à configurer des sauvegardes régulières pour la base de données.
- Pour une production, utilisez HTTPS avec Let's Encrypt.
