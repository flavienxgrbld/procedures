#!/usr/bin/env bash
set -euo pipefail

# Détection d'OS et gestionnaire de paquets
OS_ID=""
OS_NAME=""
OS_VERSION_ID=""
OS_ID_LIKE=""
PKG_MANAGER=""

LOG_FILE="/var/log/install_script.log"
TEMP_FILES=()
INSTALLED_PACKAGES=()
BACKUP_FILES=()
SCRIPT_NAME="${0##*/}"
SCRIPT_START_TIME=$(date +%s)

cleanup() {
    local exit_code=$?
    local end_time=$(date +%s)
    local duration=$((end_time - SCRIPT_START_TIME))

    for file in "${TEMP_FILES[@]}"; do
        if [ -f "$file" ] || [ -d "$file" ]; then
            rm -rf "$file" 2>/dev/null || true
        fi
    done

    if [ $exit_code -eq 0 ]; then
        log "SUCCESS" "Script $SCRIPT_NAME terminé avec succès en ${duration}s"
        success "Installation terminée avec succès"
    else
        log "ERROR" "Script $SCRIPT_NAME échoué (code: $exit_code) après ${duration}s"
        error_exit "Installation échouée. Consultez $LOG_FILE pour plus de détails."
    fi
}

trap cleanup EXIT

log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
    echo "[$timestamp] [$level] [$SCRIPT_NAME] $message" >> "$LOG_FILE" 2>/dev/null || true

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
            [ "${DEBUG:-0}" = "1" ] && echo "🔍 $message"
            ;;
    esac
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

add_temp_file() {
    TEMP_FILES+=("$1")
}

backup_file() {
    local file="$1"
    local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"

    if [ -f "$file" ]; then
        cp "$file" "$backup"
        BACKUP_FILES+=("$backup")
        debug "Sauvegarde créée: $backup"
    fi
}

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

mark_package_installed() {
    INSTALLED_PACKAGES+=("$1")
}

rollback_packages() {
    if [ ${#INSTALLED_PACKAGES[@]} -gt 0 ]; then
        warn "Rollback des packages installés..."
        pkg_remove "${INSTALLED_PACKAGES[@]}"
        INSTALLED_PACKAGES=()
    fi
}

require_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        error_exit "Commande requise introuvable: $1"
    fi
}

check_prerequisites() {
    local prerequisites=("$@")

    info "Vérification des prérequis..."
    for cmd in "${prerequisites[@]}"; do
        require_command "$cmd"
    done
    debug "Tous les prérequis sont satisfaits"
}

ensure_download_tool() {
    if command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1; then
        return 0
    fi

    info "Installation de curl pour le téléchargement de fichiers"
    if command -v apt-get >/dev/null 2>&1; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq || true
        apt-get install -y curl || apt-get install -y wget || true
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y curl || true
    elif command -v yum >/dev/null 2>&1; then
        yum install -y curl || true
    elif command -v zypper >/dev/null 2>&1; then
        zypper install -y curl || true
    elif command -v pacman >/dev/null 2>&1; then
        pacman -S --noconfirm curl || true
    fi
}

ensure_root() {
    if [ "$(id -u)" -ne 0 ]; then
        error_exit "Ce script doit être exécuté en root"
    fi
}

# Détection OS

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

detect_package_manager() {
    if command -v apt-get >/dev/null 2>&1; then
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
            apt-get update -qq
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

pkg_install() {
    debug "Installation des packages: $*"
    case "$PKG_MANAGER" in
        apt)
            if ! apt-get update -qq; then
                warn "Échec de apt-get update, poursuite avec l'installation courante..."
            fi
            if ! DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"; then
                warn "Installation initiale des paquets échouée, tentative de réparation du dépôt APT puis retry..."
                DEBIAN_FRONTEND=noninteractive apt-get -f install -y || true
                apt-get update -qq || true
                if ! DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"; then
                    echo "❌ Échec de l'installation des paquets: $*" >&2
                    return 1
                fi
            fi
            ;;
        dnf)
            if ! dnf install -y "$@" 2>&1; then
                echo "❌ Échec de l'installation des paquets: $*" >&2
                return 1
            fi
            ;;
        yum)
            if ! yum install -y "$@" 2>&1; then
                echo "❌ Échec de l'installation des paquets: $*" >&2
                return 1
            fi
            ;;
        zypper)
            if ! zypper install -y "$@" 2>&1; then
                echo "❌ Échec de l'installation des paquets: $*" >&2
                return 1
            fi
            ;;
        pacman)
            if ! pacman -S --noconfirm "$@" 2>&1; then
                echo "❌ Échec de l'installation des paquets: $*" >&2
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
            apt-get remove -y "$@"
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

install_php() {
    local php_version="${1:-8.2}"
    case "$PKG_MANAGER" in
        apt)
            if ! pkg_install "php${php_version}" "php${php_version}-cli" "php${php_version}-common" "php${php_version}-mysql" "php${php_version}-zip" "php${php_version}-gd" "php${php_version}-mbstring" "php${php_version}-curl" "php${php_version}-xml" "php${php_version}-bcmath" "php${php_version}-json" "php${php_version}-intl" "php${php_version}-fpm"; then
                pkg_install "php" "php-cli" "php-common" "php-mysql" "php-zip" "php-gd" "php-mbstring" "php-curl" "php-xml" "php-bcmath" "php-json" "php-intl" "php-fpm"
            fi
            ;;
        dnf|yum)
            pkg_install "php" "php-cli" "php-common" "php-mysqlnd" "php-zip" "php-gd" "php-mbstring" "php-curl" "php-xml" "php-bcmath" "php-json" "php-intl" "php-fpm"
            ;;
        zypper)
            pkg_install "php" "php-cli" "php-common" "php-mysql" "php-zip" "php-gd" "php-mbstring" "php-curl" "php-xml" "php-bcmath" "php-json" "php-intl" "php-fpm"
            ;;
        pacman)
            pkg_install "php" "php-cli" "php-common" "php-mysql" "php-zip" "php-gd" "php-mbstring" "php-curl" "php-xml" "php-bcmath" "php-json" "php-intl" "php-fpm"
            ;;
    esac
}

