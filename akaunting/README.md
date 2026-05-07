# Installation d'Akaunting

## Description
Akaunting est un logiciel de comptabilité open source gratuit permettant de gérer les finances d'une entreprise. Il offre des fonctionnalités telles que la facturation, la gestion des dépenses, les rapports financiers, etc.

## Prérequis
- Système d'exploitation : Ubuntu/Debian Linux (ou autres distributions compatibles)
- Accès : root ou sudo
- Connexion Internet pour télécharger les dépendances
- Espace disque : au moins 1 Go d’espace libre
- Mémoire : au moins 512 Mo de RAM

## Installation

### Méthode automatique (recommandée)
Exécutez le script d'installation fourni :

```bash
bash install_akaunting.sh
```

### Installation manuelle (étapes détaillées)
Si vous préférez installer Akaunting manuellement, suivez les étapes ci-dessous :

1. **Mise à jour du système**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Installation de PHP 8.1 et des extensions nécessaires**
   ```bash
   sudo apt install php8.1 php8.1-cli php8.1-common php8.1-curl php8.1-xml php8.1-zip php8.1-mbstring php8.1-bcmath php8.1-mysql -y
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

5. **Sécurisation de MySQL (recommandé)**
   ```bash
   sudo mysql_secure_installation
   ```

6. **Installation de Composer**
   ```bash
   curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
   ```

7. **Installation de Git (si nécessaire)**
   ```bash
   sudo apt install git -y
   ```

8. **Téléchargement d'Akaunting**
   ```bash
   cd /var/www
   sudo git clone https://github.com/akaunting/akaunting.git
   cd akaunting
   ```

9. **Installation des dépendances PHP**
   ```bash
   composer install --no-dev --optimize-autoloader
   ```

10. **Configuration de l'application**
    ```bash
    cp .env.example .env
    php artisan key:generate
    php artisan storage:link
    ```

11. **Configuration de la base de données**
    Modifiez le fichier `.env` :
    ```bash
    nano .env
    ```
    Renseignez :
    ```
    DB_DATABASE=akaunting
    DB_USERNAME=utilisateur
    DB_PASSWORD=motdepasse
    ```

    Puis lancez :
    ```bash
    php artisan migrate --force
    ```

12. **Permissions**
    ```bash
    sudo chown -R www-data:www-data /var/www/akaunting
    sudo chmod -R 775 storage bootstrap/cache
    ```

## Configuration

Après l'installation, configurez Akaunting via l'interface web :

1. Accédez à : `http://votre-serveur/akaunting`
2. Suivez l'assistant d'installation pour configurer la base de données et créer un compte administrateur

### Configuration Apache (si nécessaire)

Créez un fichier de configuration :

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

    ErrorLog ${APACHE_LOG_DIR}/akaunting_error.log
    CustomLog ${APACHE_LOG_DIR}/akaunting_access.log combined
</VirtualHost>
```

Activez les modules et le site :

```bash
sudo a2enmod rewrite
sudo a2ensite akaunting.conf
sudo systemctl reload apache2
```

## Vérification

- Vérifiez qu’Apache est actif :
  ```bash
  sudo systemctl status apache2
  ```

- Vérifiez que MySQL est actif :
  ```bash
  sudo systemctl status mysql
  ```

- Accédez à l'application via votre navigateur
- Testez la création d'une facture ou d'une dépense

## Dépannage

- En cas d'erreurs PHP, consultez les logs :
  ```bash
  sudo tail -f /var/log/apache2/error.log
  ```
- Vérifiez les modules PHP installés :
  ```bash
  php -m
  ```
- Pour les problèmes de base de données, vérifiez le fichier `.env`

## Documentation
- Site officiel : https://akaunting.com/
- Documentation : https://akaunting.com/docs
- GitHub : https://github.com/akaunting/akaunting

## Notes
- Akaunting est compatible avec plusieurs langues et devises
- Pensez à configurer des sauvegardes régulières de la base de données
- En production, utilisez HTTPS (Let's Encrypt recommandé)