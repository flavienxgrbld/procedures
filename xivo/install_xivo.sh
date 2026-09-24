#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
COMMON_SCRIPT="${REPO_ROOT}/install_common.sh"

if [ ! -f "$COMMON_SCRIPT" ]; then
    COMMON_SCRIPT="/tmp/install_common.sh"
    if [ ! -f "$COMMON_SCRIPT" ]; then
        curl -fsSL "https://raw.githubusercontent.com/flavienxgrbld/install-scripts/main/root/common/install_common.sh" -o "$COMMON_SCRIPT"
    fi

    if ! bash -n "$COMMON_SCRIPT" >/dev/null 2>&1; then
        echo "⚠️ Le fichier commun distant est invalide syntaxiquement. Le script local du dépôt sera utilisé si disponible." >&2
        COMMON_SCRIPT=""
    fi
fi

if [ -z "$COMMON_SCRIPT" ] || [ ! -f "$COMMON_SCRIPT" ]; then
    echo "❌ Impossible de charger le script commun install_common.sh. Vérifiez le dépôt ou réinstallez le projet." >&2
    exit 1
fi

source "$COMMON_SCRIPT"

ensure_root
detect_os
detect_package_manager

info "XiVO - PBX / téléphonie IP"

XIVO_REPO_URL="${XIVO_REPO_URL:-https://apt.xivo.io/}"
XIVO_KEY_URL="${XIVO_KEY_URL:-${XIVO_REPO_URL%/}/xivo-release.gpg}"
XIVO_REPO_CODENAME="${XIVO_REPO_CODENAME:-}"
XIVO_PACKAGE="${XIVO_PACKAGE:-xivo}"
XIVO_SERVICE="${XIVO_SERVICE:-xivo}"

check_xivo_compatibility() {
    local os_id="${OS_ID:-}"
    local version_id="${OS_VERSION_ID:-}"
    local codename="${VERSION_CODENAME:-${UBUNTU_CODENAME:-${DEBIAN_CODENAME:-}}}"

    case "${os_id}:${version_id}" in
        debian:11|debian:12|ubuntu:20.04|ubuntu:22.04)
            return 0
            ;;
        *)
            ;;
    esac

    case "$codename" in
        bullseye|bookworm|focal|jammy)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

if ! check_xivo_compatibility; then
    fatal "Distribution non supportée pour XiVO : ${OS_NAME:-$OS_ID} ${OS_VERSION_ID:-$VERSION_CODENAME}. Utilisez Debian 11/12 ou Ubuntu 20.04/22.04."
fi

echo "=== Préparation de l'environnement XiVO ==="
case "$PKG_MANAGER" in
    apt)
        if ! pkg_install ca-certificates curl gnupg wget lsb-release git apt-transport-https; then
            warn "L'installation des dépendances XiVO a échoué. Tentative avec apt --fix-broken puis retry..."
            DEBIAN_FRONTEND=noninteractive apt-get -f install -y || true
            pkg_install ca-certificates curl gnupg wget lsb-release git apt-transport-https || true
        fi

        if [ -z "$XIVO_REPO_CODENAME" ]; then
            XIVO_REPO_CODENAME="${VERSION_CODENAME:-${UBUNTU_CODENAME:-${DEBIAN_CODENAME:-}}}"
        fi
        if [ -z "$XIVO_REPO_CODENAME" ] && command -v lsb_release >/dev/null 2>&1; then
            XIVO_REPO_CODENAME="$(lsb_release -cs 2>/dev/null || echo bookworm)"
        fi
        case "${OS_ID}:${XIVO_REPO_CODENAME}" in
            debian:bookworm|debian:bullseye|ubuntu:jammy|ubuntu:focal)
                ;;
            debian:trixie|ubuntu:noble|ubuntu:oracular|ubuntu:plucky)
                fatal "XiVO n'est pas supporté sur ${OS_NAME:-${OS_ID}} ${OS_VERSION_ID:-${XIVO_REPO_CODENAME}}. Utilisez Debian 11/12 ou Ubuntu 20.04/22.04."
                ;;
            *)
                if [ -z "$XIVO_REPO_CODENAME" ]; then
                    XIVO_REPO_CODENAME="bookworm"
                fi
                warn "Codename XiVO non pris en charge: $XIVO_REPO_CODENAME. Utilisation du codename par défaut 'bookworm'."
                XIVO_REPO_CODENAME="bookworm"
                ;;
        esac

        mkdir -p /usr/share/keyrings
        repo_added=0
        if [ ! -f /usr/share/keyrings/xivo-archive-keyring.gpg ]; then
            if curl -fsSL "$XIVO_KEY_URL" -o /tmp/xivo-release.gpg 2>/dev/null; then
                if gpg --batch --yes --dearmor -o /usr/share/keyrings/xivo-archive-keyring.gpg /tmp/xivo-release.gpg 2>/dev/null; then
                    repo_added=1
                else
                    warn "La clé GPG XiVO a été téléchargée mais n'a pas pu être convertie dans le format attendu."
                fi
            else
                warn "Le dépôt XiVO n'est pas accessible sur $XIVO_KEY_URL; le script continuera en mode de secours."
            fi
        else
            repo_added=1
        fi

        if [ "$repo_added" -eq 1 ]; then
            rm -f /etc/apt/sources.list.d/xivo.list
            printf '%s\n' "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/xivo-archive-keyring.gpg] ${XIVO_REPO_URL} ${XIVO_REPO_CODENAME} main" > /etc/apt/sources.list.d/xivo.list
            if ! apt-get update -qq; then
                warn "Le dépôt XiVO est invalide ou indisponible pour le codename ${XIVO_REPO_CODENAME}. Suppression du dépôt et basculement en mode fallback."
                rm -f /etc/apt/sources.list.d/xivo.list
                rm -f /usr/share/keyrings/xivo-archive-keyring.gpg
            fi
        else
            warn "Le dépôt XiVO n'a pas pu être ajouté. L'installation se fera en mode fallback sans dépôt officiel."
        fi
        ;;
    dnf|yum)
        pkg_install ca-certificates curl gnupg wget git
        if command -v dnf >/dev/null 2>&1; then
            dnf config-manager --add-repo "${XIVO_REPO_URL}" 2>/dev/null || true
        else
            yum-config-manager --add-repo "${XIVO_REPO_URL}" 2>/dev/null || true
        fi
        ;;
    zypper)
        pkg_install ca-certificates curl gnupg wget git
        zypper addrepo -f "${XIVO_REPO_URL}" xivo-repo 2>/dev/null || true
        ;;
    pacman)
        pkg_install ca-certificates curl gnupg wget git
        warn "XiVO n'a pas de packaging natif standard sur Arch Linux ; vérifiez la compatibilité officielle avant installation."
        ;;
    *)
        fatal "Gestionnaire de paquets non supporté pour XiVO : $PKG_MANAGER"
        ;;
esac

echo "=== Installation des paquets XiVO ==="
XIVO_INSTALLED=0
case "$PKG_MANAGER" in
    apt)
        if apt-cache show "$XIVO_PACKAGE" >/dev/null 2>&1; then
            if pkg_install "$XIVO_PACKAGE"; then
                XIVO_INSTALLED=1
            fi
        else
            warn "Le paquet '$XIVO_PACKAGE' n'est pas disponible dans le dépôt configuré. Le dépôt officiel XiVO est probablement incompatible avec cette distribution."
            warn "Asterisk n'est pas un remplacement fonctionnel de XiVO : l'installation est abandonnée."
        fi
        ;;
    dnf|yum)
        if dnf list "$XIVO_PACKAGE" >/dev/null 2>&1 || yum list "$XIVO_PACKAGE" >/dev/null 2>&1; then
            if pkg_install "$XIVO_PACKAGE"; then
                XIVO_INSTALLED=1
            fi
        else
            warn "Le paquet '$XIVO_PACKAGE' n'est pas disponible dans le dépôt configuré. Le dépôt officiel XiVO est probablement incompatible avec cette distribution."
        fi
        ;;
    zypper)
        if zypper search -i "$XIVO_PACKAGE" >/dev/null 2>&1; then
            if pkg_install "$XIVO_PACKAGE"; then
                XIVO_INSTALLED=1
            fi
        else
            warn "Le paquet '$XIVO_PACKAGE' est indisponible. Le dépôt officiel XiVO est probablement incompatible avec cette distribution."
        fi
        ;;
    pacman)
        warn "Aucune installation XiVO standard n'a été lancée sur cette distribution. Vérifiez la procédure officielle du projet."
        ;;
esac

if [ "$XIVO_INSTALLED" -eq 0 ]; then
    echo "❌ XiVO n'a pas été installé : aucun paquet XiVO valide n'est disponible sur cette distribution." >&2
    echo "Vérifiez la compatibilité du dépôt officiel XiVO pour $(. /etc/os-release; echo "${PRETTY_NAME:-${NAME:-$PKG_MANAGER}}") et choisissez une distribution supportée." >&2
    exit 1
fi

echo "=== Démarrage du service ==="
if systemctl list-unit-files | grep -q "^${XIVO_SERVICE}.service"; then
    systemctl enable --now "$XIVO_SERVICE" 2>/dev/null || true
else
    warn "Le service '$XIVO_SERVICE' n'a pas été détecté. Vérifiez le nom exact du service XiVO sur votre système."
fi

echo "=== Configuration du firewall ==="
if command -v ufw >/dev/null 2>&1; then
    ufw allow 80/tcp 2>/dev/null || true
    ufw allow 443/tcp 2>/dev/null || true
    ufw allow 5060/tcp 2>/dev/null || true
    ufw allow 5060/udp 2>/dev/null || true
    ufw allow 5061/tcp 2>/dev/null || true
    ufw allow 10000:20000/udp 2>/dev/null || true
fi

if command -v firewall-cmd >/dev/null 2>&1; then
    firewall-cmd --permanent --add-port=80/tcp 2>/dev/null || true
    firewall-cmd --permanent --add-port=443/tcp 2>/dev/null || true
    firewall-cmd --permanent --add-port=5060/tcp 2>/dev/null || true
    firewall-cmd --permanent --add-port=5060/udp 2>/dev/null || true
    firewall-cmd --permanent --add-port=5061/tcp 2>/dev/null || true
    firewall-cmd --permanent --add-port=10000-20000/udp 2>/dev/null || true
    firewall-cmd --reload 2>/dev/null || true
fi

echo
if ! systemctl list-unit-files | grep -q "^${XIVO_SERVICE}.service"; then
    printf "❌ XiVO n'est pas installé et aucun service '%s' n'a été détecté.\n" "${XIVO_SERVICE}"
    printf "Distribution compatible requise : Ubuntu/Debian supportés par le dépôt XiVO officiel.\n"
    exit 1
fi
printf "✅ XiVO a été préparé sur le système.\n"
printf "Service: %s\n" "${XIVO_SERVICE}"
printf "URL d'administration: http://%s\n" "$(hostname -I | awk '{print $1}')"
printf "Documentation: adaptez le dépôt officiel XiVO selon votre distribution et votre version.\n"
