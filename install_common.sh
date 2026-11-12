#!/usr/bin/env bash
set -euo pipefail

# Détection d'OS et gestionnaire de paquets
OS_ID=""
OS_NAME=""
OS_VERSION_ID=""
OS_ID_LIKE=""
PKG_MANAGER=""

# Variables pour la gestion d'erreurs
LOG_FILE="/var/log/install_script.log"
TEMP_FILES=()
INSTALLED_PACKAGES=()
BACKUP_FILES=()
SCRIPT_NAME="${0##*/}"
SCRIPT_START_TIME=$(date +%s)

# Fonction de nettoyage
cleanup() {
    local exit_code=$?
    local end_time=$(date +%s)
    local duration=$((end_time - SCRIPT_START_TIME))

    # Nettoyer les fichiers temporaires
    for file in "${TEMP_FILES[@]}"; do
        if [ -f "$file" ] || [ -d "$file" ]; then
            rm -rf "$file" 2>/dev/null || true
        fi
    done

    # Log de la fin du script
    if [ $exit_code -eq 0 ]; then
        log "SUCCESS" "Script $SCRIPT_NAME terminé avec succès en ${duration}s"
        success "Installation terminée avec succès"
    else
        log "ERROR" "Script $SCRIPT_NAME échoué (code: $exit_code) après ${duration}s"
        error_exit "Installation échouée. Consultez $LOG_FILE pour plus de détails."
    fi
}

# Configuration du trap pour le nettoyage
trap cleanup EXIT

# Fonction de logging
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Créer le répertoire de logs si nécessaire
    mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

    # Écrire dans le fichier de log
    echo "[$timestamp] [$level] [$SCRIPT_NAME] $message" >> "$LOG_FILE" 2>/dev/null || true

    # Afficher selon le niveau
    case "$level" in
        ERROR)
            echo "❌ $message" >&2
            ;;
        WARN)
            echo "⚠️  $message" >&2
            ;;
        INFO)
            echo "ℹ️  $message"
            ;;
        SUCCESS)
            echo "✅ $message"
            ;;
        DEBUG)
            if [ "${DEBUG:-0}" = "1" ]; then echo "🔍 $message"; fi
            ;;
    esac
    return 0
}

error_exit() {
    log "ERROR" "$1"
    exit 1
}

info() {
    log "INFO" "$1"
}

success() {
    log "SUCCESS" "$1"
}

warn() {
    log "WARN" "$1"
}

debug() {
    log "DEBUG" "$1"
}

# Fonction pour ajouter un fichier temporaire à nettoyer
add_temp_file() {
    TEMP_FILES+=("$1")
}

# Fonction pour sauvegarder un fichier avant modification
backup_file() {
    local file="$1"
    local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"

    if [ -f "$file" ]; then
        cp "$file" "$backup"
        BACKUP_FILES+=("$backup")
        debug "Sauvegarde créée: $backup"
    fi
}

# Fonction pour restaurer les sauvegardes en cas d'erreur
restore_backups() {
    for backup in "${BACKUP_FILES[@]}"; do
        local original="${backup%.backup.*}"
        if [ -f "$backup" ]; then
            mv "$backup" "$original"
            warn "Restauration de la sauvegarde: $original"
        fi
    done
    BACKUP_FILES=()
}

# Fonction pour marquer un package comme installé (pour rollback)
mark_package_installed() {
    INSTALLED_PACKAGES+=("$1")
}

# Fonction de rollback des packages installés
rollback_packages() {
    if [ ${#INSTALLED_PACKAGES[@]} -gt 0 ]; then
        warn "Rollback des packages installés..."
        pkg_remove "${INSTALLED_PACKAGES[@]}"
        INSTALLED_PACKAGES=()
    fi
}

# Fonction pour vérifier si une commande existe
require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        error_exit "Commande requise introuvable: $1"
    fi
}

# Fonction pour vérifier les prérequis
check_prerequisites() {
    local prerequisites=("$@")

    info "Vérification des prérequis..."
    for cmd in "${prerequisites[@]}"; do
        require_command "$cmd"
    done
    debug "Tous les prérequis sont satisfaits"
}

# Fonction améliorée pour l'installation de packages avec rollback
pkg_install_with_rollback() {
    local packages=("$@")
    local failed_packages=()
    local success_count=0

    for pkg in "${packages[@]}"; do
        if pkg_install "$pkg" 2>/dev/null; then
            mark_package_installed "$pkg"
            success_count=$((success_count + 1))
        else
            failed_packages+=("$pkg")
            debug "Impossible d'installer le package: $pkg (continuant...)"
        fi
    done
    
    if [ $success_count -eq 0 ] && [ ${#failed_packages[@]} -gt 0 ]; then
        error_exit "Aucun des packages n'a pu être installé: ${failed_packages[*]}"
    fi
    
    if [ ${#failed_packages[@]} -gt 0 ]; then
        warn "Quelques packages n'ont pas pu être installés: ${failed_packages[*]}"
    fi
}

# Fonction pour vérifier l'état d'un service
check_service_status() {
    local service="$1"
    local expected_status="${2:-active}"

    if ! service_is_active "$service"; then
        if [ "$expected_status" = "active" ]; then
            error_exit "Le service $service n'est pas actif"
        fi
    else
        if [ "$expected_status" = "inactive" ]; then
            error_exit "Le service $service est actif alors qu'il ne devrait pas l'être"
        fi
    fi
}

# Fonction pour tester une URL avec timeout
check_url_with_timeout() {
    local url="$1"
    local timeout="${2:-10}"

    ensure_download_tool
    if command -v curl >/dev/null 2>&1; then
        if ! timeout "$timeout" curl -fsSL --max-time "$timeout" "$url" >/dev/null 2>&1; then
            error_exit "URL inaccessible: $url"
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! timeout "$timeout" wget --spider -q --timeout="$timeout" "$url" 2>/dev/null; then
            error_exit "URL inaccessible: $url"
        fi
    else
        error_exit "Ni curl ni wget n'est installé pour vérifier l'URL: $url"
    fi
}

# Fonction pour télécharger un fichier avec gestion d'erreurs
download_file_safe() {
    local url="$1"
    local dest="$2"
    local temp_file="${dest}.tmp"

    add_temp_file "$temp_file"

    debug "Téléchargement de $url vers $dest"
    if ! download_file "$url" "$temp_file"; then
        error_exit "Échec du téléchargement: $url"
    fi

    mv "$temp_file" "$dest"
    debug "Téléchargement réussi: $dest"
}

# Fonction pour valider une configuration
validate_config() {
    local config_file="$1"
    local validator="${2:-}"

    if [ ! -f "$config_file" ]; then
        error_exit "Fichier de configuration manquant: $config_file"
    fi

    if [ -n "$validator" ] && ! $validator "$config_file"; then
        error_exit "Validation échouée pour: $config_file"
    fi

    debug "Configuration validée: $config_file"
}

# Fonction pour créer un répertoire avec vérification
create_dir() {
    local dir="$1"

    if ! mkdir -p "$dir"; then
        error_exit "Impossible de créer le répertoire: $dir"
    fi

    debug "Répertoire créé: $dir"
}

# Fonction pour changer les permissions avec vérification
set_permissions() {
    local path="$1"
    local permissions="$2"
    local owner="${3:-}"

    if ! chmod "$permissions" "$path"; then
        error_exit "Impossible de changer les permissions de: $path"
    fi

    if [ -n "$owner" ]; then
        if ! chown "$owner" "$path"; then
            error_exit "Impossible de changer le propriétaire de: $path"
        fi
    fi

    debug "Permissions définies pour $path: $permissions ${owner:+($owner)}"
}

ensure_download_tool() {
    if command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1; then
        return 0
    fi

    info "Installation de curl pour le téléchargement de fichiers"
    pkg_install_with_rollback curl || pkg_install_with_rollback wget
}

ensure_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error_exit "Ce script doit être exécuté en root"
    fi
}

# Detect OS from /etc/os-release
detect_os() {
    if [ ! -r /etc/os-release ]; then
        error_exit "Impossible de détecter l'OS : /etc/os-release absent"
    fi
    # shellcheck disable=SC1091
    . /etc/os-release
    OS_ID=${ID,,}
    OS_NAME=${NAME:-$OS_ID}
    OS_VERSION_ID=${VERSION_ID:-}
    OS_ID_LIKE=${ID_LIKE:-}
}

is_debian_family() {
    case "${OS_ID} ${OS_ID_LIKE}" in
        *debian*|*ubuntu*) return 0 ;; 
        *) return 1 ;;
    esac
}

is_ubuntu() {
    [ "${OS_ID}" = "ubuntu" ]
}

is_redhat_family() {
    case "${OS_ID} ${OS_ID_LIKE}" in
        *rhel*|*fedora*|*centos*|*rocky*|*almalinux*|*amazonlinux*|*oraclelinux*) return 0 ;; 
        *) return 1 ;;
    esac
}

is_suse_family() {
    case "${OS_ID} ${OS_ID_LIKE}" in
        *suse*|*opensuse*) return 0 ;; 
        *) return 1 ;;
    esac
}

is_pacman_family() {
    [ "${OS_ID}" = "arch" ]
}

get_major_version() {
    local version="$1"
    printf '%s' "${version%%.*}"
}

# Detect package manager by availability
detect_package_manager() {
    if command -v apt >/dev/null 2>&1; then
        PKG_MANAGER="apt"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
    elif command -v zypper >/dev/null 2>&1; then
        PKG_MANAGER="zypper"
    elif command -v pacman >/dev/null 2>&1; then
        PKG_MANAGER="pacman"
    else
        error_exit "Aucun gestionnaire de paquets supporté détecté"
    fi
}

pkg_update() {
    case "$PKG_MANAGER" in
        apt)
            apt-get update
            ;;
        dnf)
            dnf makecache --refresh
            ;;
        yum)
            yum makecache
            ;;
        zypper)
            zypper refresh
            ;;
        pacman)
            pacman -Sy --noconfirm
            ;;
    esac
}

pkg_upgrade() {
    case "$PKG_MANAGER" in
        apt)
            DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
            ;;
        dnf)
            dnf upgrade -y
            ;;
        yum)
            yum update -y
            ;;
        zypper)
            zypper update -y
            ;;
        pacman)
            pacman -Syu --noconfirm
            ;;
    esac
}

pkg_install() {
    debug "Installation des packages: $*"
    case "$PKG_MANAGER" in
        apt)
            if ! DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" 2>&1; then
                return 1
            fi
            ;;
        dnf)
            if ! dnf install -y "$@" 2>&1; then
                return 1
            fi
            ;;
        yum)
            if ! yum install -y "$@" 2>&1; then
                return 1
            fi
            ;;
        zypper)
            if ! zypper install -y "$@" 2>&1; then
                return 1
            fi
            ;;
        pacman)
            if ! pacman -S --noconfirm "$@" 2>&1; then
                return 1
            fi
            ;;
    esac
    debug "Packages installés avec succès: $*"
    return 0
}

pkg_remove() {
    case "$PKG_MANAGER" in
        apt)
            apt remove -y "$@"
            ;;
        dnf)
            dnf remove -y "$@"
            ;;
        yum)
            yum remove -y "$@"
            ;;
        zypper)
            zypper remove -y "$@"
            ;;
        pacman)
            pacman -R --noconfirm "$@"
            ;;
    esac
}

pkg_autoremove() {
    case "$PKG_MANAGER" in
        apt)
            apt autoremove -y
            ;;
        dnf)
            dnf autoremove -y
            ;;
        yum)
            yum autoremove -y
            ;;
        zypper)
            zypper clean --all
            ;;
        pacman)
            pacman -Rns --noconfirm $(pacman -Qdtq || true)
            ;;
    esac
}

service_enable() {
    if command -v systemctl >/dev/null 2>&1; then
        systemctl enable "$1"
    elif command -v chkconfig >/dev/null 2>&1; then
        chkconfig "$1" on
    else
        warn "Impossible d'activer le service $1 automatiquement"
    fi
}

service_restart() {
    if command -v systemctl >/dev/null 2>&1; then
        systemctl restart "$1"
    else
        service "$1" restart
    fi
}

service_is_active() {
    if command -v systemctl >/dev/null 2>&1; then
        systemctl is-active --quiet "$1"
    else
        service "$1" status >/dev/null 2>&1
    fi
}

check_url() {
    ensure_download_tool
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$1" >/dev/null
    elif command -v wget >/dev/null 2>&1; then
        wget --spider -q "$1"
    else
        error_exit "Ni curl ni wget n'est installé pour vérifier l'URL: $1"
    fi
}

download_file() {
    local url="$1"
    local dest="$2"

    ensure_download_tool
    debug "Téléchargement de $url vers $dest"
    if command -v curl >/dev/null 2>&1; then
        if ! curl -fsSL "$url" -o "$dest"; then
            error_exit "Échec du téléchargement avec curl: $url"
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget -q "$url" -O "$dest"; then
            error_exit "Échec du téléchargement avec wget: $url"
        fi
    else
        error_exit "Ni curl ni wget n'est installé pour télécharger: $url"
    fi
    debug "Téléchargement réussi: $dest"
}

# Installation de PHP sur différents OS
install_php() {
    local php_version="${1:-8.2}"

    case "$PKG_MANAGER" in
        apt)
            # Dépendances préalables, installées une par une : software-properties-common
            # n'existe plus sur Debian 13 et ferait échouer toute la liste.
            local dep
            for dep in lsb-release ca-certificates apt-transport-https gnupg curl wget; do
                pkg_install "$dep" >/dev/null 2>&1 || true
            done
            if is_ubuntu; then
                pkg_install software-properties-common >/dev/null 2>&1 || true
            fi

            # Le module json est intégré à PHP 8 : il n'y a plus de paquet phpX-json.
            local php_pkgs=("php${php_version}" "php${php_version}-cli" "php${php_version}-common" "php${php_version}-mysql" "php${php_version}-zip" "php${php_version}-gd" "php${php_version}-mbstring" "php${php_version}-curl" "php${php_version}-xml" "php${php_version}-bcmath" "php${php_version}-intl" "php${php_version}-fpm")

            if pkg_install "${php_pkgs[@]}" 2>/dev/null; then
                success "PHP ${php_version} installé depuis les dépôts officiels"
                return 0
            fi

            info "PHP ${php_version} absent des dépôts officiels, ajout du dépôt externe..."
            if is_ubuntu; then
                add-apt-repository -y ppa:ondrej/php || warn "Impossible d'ajouter ppa:ondrej/php"
            else
                local codename
                codename=$(lsb_release -sc 2>/dev/null || (. /etc/os-release && echo "${VERSION_CODENAME:-bookworm}"))
                local sury_keyring="/usr/share/keyrings/deb.sury.org-php.gpg"
                if curl -fsSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb \
                    && dpkg -i /tmp/debsuryorg-archive-keyring.deb && [ -f "$sury_keyring" ]; then
                    if ! curl -fsS "https://packages.sury.org/php/dists/${codename}/Release" >/dev/null 2>&1; then
                        warn "Version ${codename} non gérée par le dépôt Sury, utilisation de bookworm"
                        codename="bookworm"
                    fi
                    echo "deb [signed-by=${sury_keyring}] https://packages.sury.org/php/ ${codename} main" > /etc/apt/sources.list.d/sury-php.list
                    info "Dépôt Sury ajouté pour ${codename}"
                else
                    warn "Impossible d'installer la clé du dépôt Sury"
                    rm -f /etc/apt/sources.list.d/sury-php.list
                fi
                rm -f /tmp/debsuryorg-archive-keyring.deb
            fi
            pkg_update || true

            if pkg_install "${php_pkgs[@]}" 2>/dev/null; then
                success "PHP ${php_version} installé depuis le dépôt externe"
            else
                info "PHP ${php_version} indisponible, installation de la version PHP de la distribution..."
                pkg_install php php-cli php-common php-mysql php-zip php-gd php-mbstring php-curl php-xml php-bcmath php-intl php-fpm \
                    || error_exit "Impossible d'installer PHP"
                success "PHP de la distribution installé"
            fi
            ;;

        dnf)
            # Pour RHEL/CentOS/Fedora, utiliser les dépôts Remi
            pkg_install https://dl.fedoraproject.org/pub/epel/epel-release-latest-${OS_VERSION_ID%%.*}.noarch.rpm || true
            pkg_install https://rpms.remirepo.net/enterprise/remi-release-${OS_VERSION_ID%%.*}.rpm || true

            if command -v dnf >/dev/null 2>&1; then
                dnf config-manager --set-enabled remi
                dnf module reset php -y
                dnf module enable php:remi-${php_version} -y
            fi

            pkg_install "php" "php-cli" "php-common" "php-mysqlnd" "php-zip" "php-gd" "php-mbstring" "php-curl" "php-xml" "php-bcmath" "php-intl" "php-fpm"
            ;;

        yum)
            # Pour CentOS/RHEL 7
            pkg_install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm || true
            pkg_install https://rpms.remirepo.net/enterprise/remi-release-7.rpm || true

            yum-config-manager --enable remi remi-php${php_version//./} || true

            pkg_install "php" "php-cli" "php-common" "php-mysql" "php-zip" "php-gd" "php-mbstring" "php-curl" "php-xml" "php-bcmath" "php-intl" "php-fpm"
            ;;

        zypper)
            # Pour SUSE
            pkg_install "php${php_version//./}" "php${php_version//./}-cli" "php${php_version//./}-mysql" "php${php_version//./}-zip" "php${php_version//./}-gd" "php${php_version//./}-mbstring" "php${php_version//./}-curl" "php${php_version//./}-xml" "php${php_version//./}-bcmath" "php${php_version//./}-json" "php${php_version//./}-intl" "php${php_version//./}-fpm"
            ;;

        pacman)
            # Pour Arch Linux
            pkg_install "php" "php-fpm" "php-gd" "php-intl" "php-mysqli"
            ;;
    esac
}

# Installation de MariaDB/MySQL sur différents OS
install_database() {
    info "Installation de la base de données..."
    case "$PKG_MANAGER" in
        apt)
            # Debian 13 peut avoir une configuration MariaDB différente
            # Essayer d'abord l'installation standard
            if ! pkg_install_with_rollback mariadb-server mariadb-client 2>/dev/null; then
                info "Installation standard MariaDB échouée, essai du paquet server uniquement..."
                pkg_install_with_rollback mariadb-server || \
                pkg_install_with_rollback mysql-server || \
                error_exit "Impossible d'installer MariaDB ou MySQL"
            fi
            
            # Vérifier le service approprié
            local db_service="mariadb"
            if ! systemctl list-units --all | grep -q "mariadb.service"; then
                if systemctl list-units --all | grep -q "mysql.service"; then
                    db_service="mysql"
                fi
            fi
            
            service_enable "$db_service" || warn "Impossible d'activer le service $db_service"
            service_restart "$db_service" || warn "Impossible de redémarrer le service $db_service"
            sleep 2  # Attendre que le service démarre
            check_service_status "$db_service" || warn "Service $db_service peut ne pas être active"
            ;;

        dnf)
            pkg_install_with_rollback mariadb-server mariadb || \
            error_exit "Impossible d'installer MariaDB"
            service_enable mariadb
            service_restart mariadb
            check_service_status mariadb
            ;;

        yum)
            pkg_install_with_rollback mariadb-server mariadb || \
            error_exit "Impossible d'installer MariaDB"
            service_enable mariadb
            service_restart mariadb
            check_service_status mariadb
            ;;

        zypper)
            pkg_install_with_rollback mariadb mariadb-client || \
            error_exit "Impossible d'installer MariaDB"
            service_enable mysql
            service_restart mysql
            check_service_status mysql
            ;;

        pacman)
            pkg_install_with_rollback mariadb || \
            error_exit "Impossible d'installer MariaDB"
            mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
            service_enable mariadb
            service_restart mariadb
            check_service_status mariadb
            ;;
    esac
    success "Base de données installée et démarrée"
}

# Installation d'Apache/Nginx sur différents OS
install_webserver() {
    local webserver="${1:-apache}"

    info "Installation du serveur web: $webserver"
    case "$webserver" in
        apache)
            case "$PKG_MANAGER" in
                apt)
                    pkg_install_with_rollback apache2
                    service_enable apache2
                    service_restart apache2
                    check_service_status apache2
                    ;;
                dnf)
                    pkg_install_with_rollback httpd
                    service_enable httpd
                    service_restart httpd
                    check_service_status httpd
                    ;;
                yum)
                    pkg_install_with_rollback httpd
                    service_enable httpd
                    service_restart httpd
                    check_service_status httpd
                    ;;
                zypper)
                    pkg_install_with_rollback apache2
                    service_enable apache2
                    service_restart apache2
                    check_service_status apache2
                    ;;
                pacman)
                    pkg_install_with_rollback apache
                    service_enable httpd
                    service_restart httpd
                    check_service_status httpd
                    ;;
            esac
            ;;

        nginx)
            case "$PKG_MANAGER" in
                apt)
                    pkg_install_with_rollback nginx
                    service_enable nginx
                    service_restart nginx
                    check_service_status nginx
                    ;;
                dnf)
                    pkg_install_with_rollback nginx
                    service_enable nginx
                    service_restart nginx
                    check_service_status nginx
                    ;;
                yum)
                    pkg_install_with_rollback nginx
                    service_enable nginx
                    service_restart nginx
                    check_service_status nginx
                    ;;
                zypper)
                    pkg_install_with_rollback nginx
                    service_enable nginx
                    service_restart nginx
                    check_service_status nginx
                    ;;
                pacman)
                    pkg_install_with_rollback nginx
                    service_enable nginx
                    service_restart nginx
                    check_service_status nginx
                    ;;
            esac
            ;;
    esac
    success "Serveur web $webserver installé et démarré"
}

# Configuration de base de PHP pour GLPI/Zabbix
configure_php() {
    local php_version="${1:-8.2}"
    local php_ini=""
    local fpm_ini=""
    
    info "Configuration de PHP..."

    # Chercher les fichiers php.ini - priorité: 8.4, puis 8.2, puis version demandée
    if [ -f "/etc/php/8.4/cli/php.ini" ]; then
        php_ini="/etc/php/8.4/cli/php.ini"
        fpm_ini="/etc/php/8.4/fpm/php.ini"
        debug "Utilisation de PHP 8.4"
    elif [ -f "/etc/php/8.2/cli/php.ini" ]; then
        php_ini="/etc/php/8.2/cli/php.ini"
        fpm_ini="/etc/php/8.2/fpm/php.ini"
        debug "Utilisation de PHP 8.2"
    elif [ -f "/etc/php/${php_version}/cli/php.ini" ]; then
        php_ini="/etc/php/${php_version}/cli/php.ini"
        fpm_ini="/etc/php/${php_version}/fpm/php.ini"
        debug "Utilisation de PHP ${php_version}"
    else
        warn "Fichiers php.ini non trouvés, configuration PHP ignorée"
        return 0
    fi

    # Configuration PHP commune
    for ini_file in "$php_ini" "$fpm_ini"; do
        if [ -z "$ini_file" ] || [ ! -f "$ini_file" ]; then
            continue
        fi
        
        debug "Configuration de $ini_file"
        sed -i 's/^memory_limit = .*/memory_limit = 256M/' "$ini_file" 2>/dev/null
        sed -i 's/^max_execution_time = .*/max_execution_time = 600/' "$ini_file" 2>/dev/null
        sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 50M/' "$ini_file" 2>/dev/null
        sed -i 's/^post_max_size = .*/post_max_size = 50M/' "$ini_file" 2>/dev/null
        sed -i 's/^max_input_time = .*/max_input_time = 300/' "$ini_file" 2>/dev/null
    done

    # Redémarrer PHP-FPM si le service existe
    if systemctl is-active --quiet php8.4-fpm 2>/dev/null; then
        systemctl restart php8.4-fpm 2>/dev/null || true
        debug "PHP 8.4 FPM redémarré"
    elif systemctl is-active --quiet php8.2-fpm 2>/dev/null; then
        systemctl restart php8.2-fpm 2>/dev/null || true
        debug "PHP 8.2 FPM redémarré"
    fi

    success "Configuration PHP terminée"
}

# ---------------------------------------------------------------------------
# Fonctions utilitaires ajoutées
# ---------------------------------------------------------------------------

# version_ge A B : vrai si la version A est supérieure ou égale à B
version_ge() {
    [ "$(printf '%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

# random_password [longueur] : mot de passe alphanumérique aléatoire
random_password() {
    local length="${1:-24}"
    tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "$length" || true
}

# github_latest_tag owner/depot [valeur_par_defaut]
# Affiche le tag de la dernière version publiée, ou la valeur par défaut.
github_latest_tag() {
    local repo="$1"
    local fallback="${2:-}"
    local tag=""
    tag=$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null \
        | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/') || true
    printf '%s' "${tag:-$fallback}"
}

# install_php_min VERSION_MIN
# Installe la version de PHP de la distribution si elle est suffisante,
# sinon VERSION_MIN depuis le dépôt Sury (Debian) ou ppa:ondrej/php (Ubuntu).
# Définit PHP_VERSION (ex. 8.2) avec la version réellement installée.
install_php_min() {
    local min="$1"
    local distro=""
    if [ "$PKG_MANAGER" = "apt" ]; then
        apt-get update -qq || true
        distro=$(LC_ALL=C apt-cache depends php 2>/dev/null | grep -oE 'php[0-9]+\.[0-9]+' | head -n1 | sed 's/^php//') || true
    fi
    if [ -n "$distro" ] && version_ge "$distro" "$min"; then
        install_php "$distro"
    else
        install_php "$min"
    fi
    PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
    version_ge "$PHP_VERSION" "$min" || error_exit "PHP $PHP_VERSION installé, $min minimum requis"
    info "PHP $PHP_VERSION installé"
}

# mysql_create_db BASE UTILISATEUR MOT_DE_PASSE
# Crée (ou met à jour) une base utf8mb4 et un utilisateur local dédié.
mysql_create_db() {
    local db="$1" user="$2" pass="$3"
    mysql -u root <<SQL
CREATE DATABASE IF NOT EXISTS \`${db}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${user}'@'localhost' IDENTIFIED BY '${pass}';
ALTER USER '${user}'@'localhost' IDENTIFIED BY '${pass}';
GRANT ALL PRIVILEGES ON \`${db}\`.* TO '${user}'@'localhost';
FLUSH PRIVILEGES;
SQL
}

# save_credentials FICHIER "texte" : enregistre des identifiants lisibles par root seul
save_credentials() {
    local file="$1"
    shift
    umask 077
    printf '%s\n' "$@" > "$file"
    chmod 600 "$file"
    info "Identifiants enregistrés dans $file"
}

# open_ports PORT/proto... : ouvre les ports avec ufw ou firewalld s'ils sont actifs
open_ports() {
    local p
    if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
        for p in "$@"; do ufw allow "$p" >/dev/null; done
        info "Ports ouverts dans ufw : $*"
    elif command -v firewall-cmd >/dev/null 2>&1 && firewall-cmd --state >/dev/null 2>&1; then
        for p in "$@"; do firewall-cmd --permanent --add-port="$p" >/dev/null; done
        firewall-cmd --reload >/dev/null
        info "Ports ouverts dans firewalld : $*"
    fi
}
