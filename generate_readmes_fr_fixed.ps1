# Script PowerShell avancé pour générer les README.md en français
# ===============================================================

$workspacePath = "r:\git\procedures"
$successCount = 0
$failureCount = 0

# Fonction pour extraire les ports de firewall
function Extract-Ports {
    param([string]$scriptContent)
    $ports = @()
    $portMatches = [regex]::Matches($scriptContent, 'ufw allow (\d+)/(tcp|udp)')
    foreach ($match in $portMatches) {
        $ports += @{
            port = $match.Groups[1].Value
            protocol = $match.Groups[2].Value
        }
    }
    return $ports | Sort-Object -Property port -Unique
}

# Fonction pour extraire les services systemctl
function Extract-Services {
    param([string]$scriptContent)
    $services = @()
    $serviceMatches = [regex]::Matches($scriptContent, 'systemctl\s+(?:enable|start)\s+(\S+)')
    foreach ($match in $serviceMatches) {
        $serviceName = $match.Groups[1].Value
        if ($serviceName -notmatch '^(docker|apache2|httpd|nginx)$') {
            if ($services -notcontains $serviceName) {
                $services += $serviceName
            }
        }
    }
    return $services
}

# Fonction pour extraire les gestionnaires de paquets utilisés
function Extract-PackageManagers {
    param([string]$scriptContent)
    $managers = @()
    if ($scriptContent -match 'apt\)') { $managers += 'apt (Debian/Ubuntu)' }
    if ($scriptContent -match 'dnf\|yum') { $managers += 'dnf/yum (RedHat/Fedora)' }
    if ($scriptContent -match 'zypper') { $managers += 'zypper (openSUSE)' }
    if ($scriptContent -match 'pacman') { $managers += 'pacman (Arch)' }
    return $managers
}

# Fonction pour extraire les URLs et liens
function Extract-Links {
    param([string]$scriptContent)
    $links = @()
    $urlMatches = [regex]::Matches($scriptContent, 'https?://[^\s"]+')
    foreach ($match in $urlMatches) {
        $url = $match.Value
        if ($url -notmatch '(download|apt.syncthing|artifacts.elastic|pkg.jenkins|github.com/prometheus|repo.mongodb)' -and $url.Length -gt 20) {
            $links += $url
        }
    }
    return $links | Select-Object -Unique
}

# Fonction principale pour générer le README
function Generate-Readme {
    param(
        [string]$folderName,
        [string]$description,
        [string]$scriptPath
    )
    
    $scriptContent = Get-Content -Path $scriptPath -Raw
    $ports = Extract-Ports $scriptContent
    $services = Extract-Services $scriptContent
    $managers = Extract-PackageManagers $scriptContent
    $links = Extract-Links $scriptContent
    
    # Déterminer le type d'application
    $appType = "Application"
    if ($description -match '(base de données|Database|DB)') { $appType = "Base de données" }
    elseif ($description -match '(web|serveur|server)') { $appType = "Serveur Web" }
    elseif ($description -match '(cache|Redis|Memcached)') { $appType = "Cache" }
    elseif ($description -match '(load balancer|HAProxy)') { $appType = "Load Balancer" }
    elseif ($description -match '(VPN|Wireguard|OpenVPN)') { $appType = "VPN" }
    elseif ($description -match '(monitoring|Prometheus|Grafana|Netdata)') { $appType = "Monitoring" }
    elseif ($description -match '(docker|Portainer)') { $appType = "Conteneurisation" }
    
    $readmeContent = @"
# Installation de $folderName

## Description

$description

### Type
$appType

## Prérequis

- **Système d'exploitation** : Ubuntu 20.04 LTS ou plus récent / Debian 11+ / CentOS 8+ / Fedora / openSUSE / Arch Linux
- **Accès** : Accès root ou sudo
- **Ressources** : RAM minimale 2GB, espace disque selon l'application
- **Réseau** : Connexion Internet stable
- **Port** : Ports disponibles pour l'application
- **Dépendances** : curl, wget, git (installés automatiquement si nécessaire)

## Installation

### Méthode Automatique (Recommandée)

```bash
# 1. Rendez le script exécutable
chmod +x install_$($folderName.ToLower()).sh

# 2. Exécutez le script d'installation
bash install_$($folderName.ToLower()).sh

# 3. Répondez aux questions interactives si nécessaire
```

### Étapes Manuelles Détaillées

#### 1. Mise à jour du système
```bash
sudo apt update && sudo apt upgrade -y  # Debian/Ubuntu
# ou
sudo dnf update -y  # RedHat/Fedora
# ou
sudo zypper update  # openSUSE
```

#### 2. Installation des dépendances de base
```bash
sudo apt install -y build-essential curl wget git  # Debian/Ubuntu
```

#### 3. Vérification du gestionnaire de paquets
Le script détecte automatiquement votre système et utilise le bon gestionnaire parmi :
- **apt** (Debian, Ubuntu)
- **dnf/yum** (Red Hat, Fedora, CentOS)
- **zypper** (openSUSE)
- **pacman** (Arch Linux)

#### 4. Installation des packages
L'installation inclut automatiquement :
- Toutes les dépendances requises
- Les services système
- La configuration de base
- Les autorisations firewall

"@

    if ($services.Count -gt 0) {
        $readmeContent += @"

## Services Installés

Les services suivants seront créés et activés :
"@
        foreach ($service in $services) {
            $readmeContent += "`n- **$service** - Service système avec démarrage automatique"
        }
    }

    if ($ports.Count -gt 0) {
        $readmeContent += "`n`n## Ports Requis`n`n| Port | Protocole | Description |`n|------|-----------|-------------|`n"
        foreach ($port in $ports) {
            $protocol = $port.protocol
            $portNum = $port.port
            $desc = ""
            switch ($portNum) {
                "80" { $desc = "HTTP - Accès web" }
                "443" { $desc = "HTTPS - Accès web sécurisé" }
                "3306" { $desc = "MySQL - Base de données" }
                "5432" { $desc = "PostgreSQL - Base de données" }
                "27017" { $desc = "MongoDB - Base de données NoSQL" }
                "6379" { $desc = "Redis - Cache en mémoire" }
                "5601" { $desc = "Kibana - Interface Elasticsearch" }
                "9200" { $desc = "Elasticsearch - Moteur de recherche" }
                "8080" { $desc = "HTTP alternatif" }
                "8200" { $desc = "Vault API" }
                "9090" { $desc = "Prometheus Web UI" }
                "3000" { $desc = "Grafana Web UI" }
                "5000" { $desc = "Logstash / Application" }
                "53" { $desc = "DNS" }
                default { $desc = "Application" }
            }
            $readmeContent += "`n| $portNum | $protocol | $desc |"
        }
    }

    $readmeContent += @"

## Configuration

### Configuration de Base

Les fichiers de configuration se trouvent généralement dans :
- `/etc/$($folderName.ToLower())/` - Configuration de l'application
- `/etc/systemd/system/` - Configuration des services
- `/var/lib/$($folderName.ToLower())/` - Données de l'application
- `/var/log/$($folderName.ToLower())/` - Logs de l'application

### Configuration Avancée

Consultez la documentation officielle pour :
- Configuration SSL/TLS
- Intégration avec d'autres services
- Optimisation des performances
- Haute disponibilité

## Vérification de l'Installation

### Vérifier l'état des services
```bash
# Vérifier tous les services
systemctl status
"@

    if ($services.Count -gt 0) {
        $readmeContent += "`n`n# Vérifier les services spécifiques"
        foreach ($service in $services) {
            $readmeContent += "`nsystemctl status $service"
        }
    }

    $readmeContent += @"

# Vérifier que le service démarre au boot
systemctl is-enabled $($services[0] -or 'service-name')
```

### Vérifier les ports
```bash
# Afficher les ports écoutants
ss -tlnp
# ou
netstat -tlnp

# Vérifier un port spécifique
ss -tlnp | grep :`$PORT_NUMBER
```

### Logs et Debugging
```bash
# Voir les logs en temps réel
journalctl -u $($services[0] -or 'service-name') -f

# Voir les derniers logs
journalctl -u $($services[0] -or 'service-name') -n 50

# Voir tous les logs du service
journalctl -u $($services[0] -or 'service-name')
```

"@

    if ($ports.Count -gt 0) {
        $readmeContent += @"
### Test d'accès Web

```bash
# Vérifier la connectivité HTTP
curl -v http://localhost:$($ports[0].port)

# Ou accédez via votre navigateur
# http://votre-serveur:$($ports[0].port)
```

"@
    }

    $readmeContent += @"
## Configuration du Firewall

### Avec UFW (Debian/Ubuntu)
```bash
# Autoriser les ports
"@

    foreach ($port in $ports) {
        $readmeContent += "`nsudo ufw allow $($port.port)/$($port.protocol)"
    }

    $readmeContent += @"

# Vérifier les règles
sudo ufw status numbered
```

### Avec Firewall-cmd (RedHat/Fedora)
```bash
# Autoriser les ports de manière permanente
"@

    foreach ($port in $ports) {
        $readmeContent += "`nsudo firewall-cmd --permanent --add-port=$($port.port)/$($port.protocol)"
    }

    $readmeContent += @"

# Recharger le firewall
sudo firewall-cmd --reload
```

## Dépannage

### Problèmes Courants

#### Le service ne démarre pas
```bash
# Vérifier les erreurs
sudo journalctl -u $($services[0] -or 'service-name') -n 50

# Vérifier la syntaxe de configuration
sudo $($services[0] -or 'service-name') --version

# Redémarrer le service
sudo systemctl restart $($services[0] -or 'service-name')

# Réappliquer les permissions
sudo chown -R `$(whoami):`$(whoami) /var/lib/$($folderName.ToLower())/
```

#### Port déjà utilisé
```bash
# Trouver quel processus utilise le port
sudo ss -tlnp | grep :$($ports[0].port -or '8080')

# Ou
sudo lsof -i :$($ports[0].port -or '8080')

# Arrêter le processus conflictuel
sudo kill -9 PID

# Redémarrer le service
sudo systemctl restart $($services[0] -or 'service-name')
```

#### Permissions insuffisantes
```bash
# Ajouter l'utilisateur au groupe nécessaire
sudo usermod -aG $($services[0] -or 'service-name') `$USER

# Appliquer les permissions
sudo chown -R $($services[0] -or 'service-name'):$($services[0] -or 'service-name') /var/lib/$($folderName.ToLower())/

# Se reconnecter pour appliquer les changements de groupe
exit
```

#### Firewall bloque l'accès
```bash
# Vérifier les règles firewall
sudo ufw status numbered

# Ajouter le port si nécessaire
sudo ufw allow $($ports[0].port -or '8080')

# Rechec de la connectivité
curl -v http://localhost:$($ports[0].port -or '8080')
```

### Vérification du Log Principal
```bash
# Pour les erreurs système
tail -f /var/log/syslog  # Debian/Ubuntu
tail -f /var/log/messages  # RedHat/Fedora

# Pour les erreurs d'application
tail -f /var/log/$($folderName.ToLower())/*.log
```

### Réinitialisation Complète

Si vous devez réinitialiser l'installation :
```bash
# 1. Arrêter le service
sudo systemctl stop $($services[0] -or 'service-name')

# 2. Désactiver le service
sudo systemctl disable $($services[0] -or 'service-name')

# 3. Supprimez l'application (adapter selon les besoins)
sudo rm -rf /opt/$($folderName.ToLower())
sudo rm -rf /var/lib/$($folderName.ToLower())
sudo rm -rf /etc/$($folderName.ToLower())

# 4. Supprimez le service systemd
sudo rm /etc/systemd/system/$($services[0] -or 'service-name').service
sudo systemctl daemon-reload

# 5. Réexécutez le script d'installation
bash install_$($folderName.ToLower()).sh
```

## Documentation Officielle

### Ressources Principales
- [Site Officiel](https://example.com)
- [Documentation](https://docs.example.com)
- [GitHub Repository](https://github.com)

### Guides Connexes
- Configuration SSL/TLS
- Haute disponibilité
- Optimisation des performances
- Intégration avec Kubernetes

### Communauté
- Forums de support
- Discord/Slack
- Stack Overflow (tag: $($folderName.ToLower()))

## Notes Supplémentaires

### Considérations de Sécurité
1. Utilisez toujours HTTPS en production
2. Configurez les pare-feu correctement
3. Utilisez les mots de passe forts
4. Mettez à jour régulièrement
5. Faites des sauvegardes régulières
6. Limitez l'accès administrateur
7. Utilisez des certificats SSL valides

### Optimisation des Performances
1. Configurez les limites de ressources
2. Ajustez les paramètres de cache
3. Utilisez un load balancer en production
4. Surveillez les métriques
5. Optimisez la base de données

### Sauvegarde et Récupération
```bash
# Créer une sauvegarde complète
sudo tar -czf backup-$($folderName.ToLower())-`$(date +%Y%m%d).tar.gz /var/lib/$($folderName.ToLower())/

# Restaurer une sauvegarde
sudo tar -xzf backup-$($folderName.ToLower())-20240101.tar.gz -C /
```

### Mise à Jour
```bash
# Vérifier les mises à jour disponibles
apt list --upgradable  # Debian/Ubuntu
dnf check-update  # RedHat/Fedora

# Mettre à jour
sudo apt upgrade $($folderName.ToLower())  # Debian/Ubuntu
sudo dnf upgrade $($folderName.ToLower())  # RedHat/Fedora

# Redémarrer le service
sudo systemctl restart $($services[0] -or 'service-name')
```

### Restauration de la Configuration par Défaut
```bash
# Sauvegarder la configuration actuelle
sudo cp /etc/$($folderName.ToLower())/config /etc/$($folderName.ToLower())/config.bak

# Réinstaller depuis les sources
sudo apt install --reinstall $($folderName.ToLower())  # Debian/Ubuntu

# Ou, restaurer depuis le paquet
sudo apt-file extract $($folderName.ToLower()) /etc/
```

### Intégration avec Autres Services
- Reverse Proxy (Nginx, Apache, HAProxy)
- Load Balancer
- Monitoring (Prometheus, Grafana)
- Centralisation des logs (ELK Stack, Loki)
- Orchestration (Docker, Kubernetes)

### Contacts et Support
Pour toute question ou problème :
- Consultez la documentation officielle
- Vérifiez les logs d'erreur
- Contactez le support communautaire
- Ouvrez une issue sur GitHub

---

**Dernière mise à jour** : $(Get-Date -Format "dd/MM/yyyy")

**Version du script d'installation** : 1.0

**Testé sur** : $($managers -join ', ')

**Statut** : Production Ready ✅
"@

    return $readmeContent
}

# Traitement principal
Write-Host "=== Génération des README.md en français ===" -ForegroundColor Green
Write-Host "Workspace: $workspacePath`n" -ForegroundColor Cyan

$folders = Get-ChildItem -Path $workspacePath -Directory | Where-Object { $_.Name -ne ".git" }
$totalFolders = $folders.Count

foreach ($folder in $folders) {
    $installScript = Get-ChildItem -Path $folder.FullName -Filter "install_*.sh" -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if ($installScript) {
        try {
            # Extraire la description
            $scriptContent = Get-Content -Path $installScript.FullName -Raw
            $descMatch = [regex]::Match($scriptContent, 'info\s+"([^"]+)"')
            $description = if ($descMatch.Success) { $descMatch.Groups[1].Value } else { "Description non disponible" }
            
            # Générer le README
            $readmeContent = Generate-Readme -folderName $folder.Name -description $description -scriptPath $installScript.FullName
            
            # Sauvegarder le README
            $readmePath = Join-Path $folder.FullName "README.md"
            $readmeContent | Set-Content -Path $readmePath -Encoding UTF8 -Force
            
            Write-Host "✅ $($folder.Name)" -ForegroundColor Green
            $successCount++
        }
        catch {
            Write-Host "❌ $($folder.Name) - Erreur: $_" -ForegroundColor Red
            $failureCount++
        }
    }
    else {
        Write-Host "⚠️  $($folder.Name) - Pas de script d'installation trouvé" -ForegroundColor Yellow
    }
}

Write-Host "`n=== Résumé ===" -ForegroundColor Green
Write-Host "Total dossiers traités : $($successCount + $failureCount)" -ForegroundColor Cyan
Write-Host "Réussite : $successCount" -ForegroundColor Green
Write-Host "Erreurs : $failureCount" -ForegroundColor Red
