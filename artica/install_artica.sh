#!/usr/bin/env bash

set -euo pipefail

COMMON_SCRIPT="/tmp/install_common.sh"
if [ ! -f "$COMMON_SCRIPT" ]; then
    curl -fsSL "https://raw.githubusercontent.com/flavienxgrbld/install-scripts/main/root/common/install_common.sh" -o "$COMMON_SCRIPT"
fi
source "$COMMON_SCRIPT"

ensure_root
detect_os
detect_package_manager

info "Artica - Gestion, proxy et sécurité réseau"

ARTICA_REPO_URL="${ARTICA_REPO_URL:-https://download.artica.fr/}"
ARTICA_PACKAGE="${ARTICA_PACKAGE:-artica}"
ARTICA_SERVICE="${ARTICA_SERVICE:-artica}"
ARTICA_HTTP_PORT="${ARTICA_HTTP_PORT:-80}"
ARTICA_HTTPS_PORT="${ARTICA_HTTPS_PORT:-443}"
ARTICA_PROXY_PORT="${ARTICA_PROXY_PORT:-3128}"

echo "=== Préparation de l'environnement Artica ==="
case "$PKG_MANAGER" in
    apt)
        pkg_install ca-certificates curl gnupg wget lsb-release git apt-transport-https

        mkdir -p /usr/share/keyrings
        if [ ! -f /usr/share/keyrings/artica-archive-keyring.gpg ]; then
            curl -fsSL "${ARTICA_REPO_URL%/}/artica.gpg" | gpg --dearmor -o /usr/share/keyrings/artica-archive-keyring.gpg 2>/dev/null || true
        fi

        if [ -f /usr/share/keyrings/artica-archive-keyring.gpg ]; then
            echo "deb [signed-by=/usr/share/keyrings/artica-archive-keyring.gpg] ${ARTICA_REPO_URL} stable main" | tee /etc/apt/sources.list.d/artica.list > /dev/null
        else
            warn "Le dépôt Artica officiel n'a pas été détecté ; l'installation continuera selon le packaging local disponible."
        fi
        pkg_update
        ;;
    dnf|yum)
        pkg_install ca-certificates curl gnupg wget git
        if command -v dnf >/dev/null 2>&1; then
            dnf config-manager --add-repo "${ARTICA_REPO_URL}" 2>/dev/null || true
        else
            yum-config-manager --add-repo "${ARTICA_REPO_URL}" 2>/dev/null || true
        fi
        ;;
    zypper)
        pkg_install ca-certificates curl gnupg wget git
        zypper addrepo -f "${ARTICA_REPO_URL}" artica-repo 2>/dev/null || true
        ;;
    pacman)
        pkg_install ca-certificates curl gnupg wget git
        warn "Artica n'a pas de packaging natif standard sur Arch Linux ; vérifiez la compatibilité officielle avant installation."
        ;;
    *)
        fatal "Gestionnaire de paquets non supporté pour Artica : $PKG_MANAGER"
        ;;
esac

echo "=== Installation du paquet Artica ==="
case "$PKG_MANAGER" in
    apt)
        if apt-cache show "$ARTICA_PACKAGE" >/dev/null 2>&1; then
            pkg_install "$ARTICA_PACKAGE"
        else
            warn "Le paquet '$ARTICA_PACKAGE' n'est pas disponible dans le dépôt configuré. Vérifiez la documentation Artica de votre version et de votre distribution."
        fi
        ;;
    dnf|yum)
        if dnf list "$ARTICA_PACKAGE" >/dev/null 2>&1 || yum list "$ARTICA_PACKAGE" >/dev/null 2>&1; then
            pkg_install "$ARTICA_PACKAGE"
        else
            warn "Le paquet '$ARTICA_PACKAGE' n'est pas disponible dans le dépôt actif. Vérifiez la compatibilité du dépôt officiel."
        fi
        ;;
    zypper)
        if zypper search -i "$ARTICA_PACKAGE" >/dev/null 2>&1; then
            pkg_install "$ARTICA_PACKAGE"
        else
            warn "Le paquet '$ARTICA_PACKAGE' est indisponible sur ce système. Vérifiez le dépôt et la version concernée."
        fi
        ;;
    pacman)
        warn "Aucune installation Artica standard n'a été lancée sur cette distribution. Consultez la procédure officielle du projet."
        ;;
esac

echo "=== Activation du service ==="
if systemctl list-unit-files | grep -q "^${ARTICA_SERVICE}.service"; then
    systemctl enable --now "$ARTICA_SERVICE" 2>/dev/null || true
else
    warn "Le service '$ARTICA_SERVICE' n'a pas été détecté. Vérifiez le nom exact du service Artica sur votre système."
fi

echo "=== Configuration du firewall ==="
if command -v ufw >/dev/null 2>&1; then
    ufw allow "$ARTICA_HTTP_PORT"/tcp 2>/dev/null || true
    ufw allow "$ARTICA_HTTPS_PORT"/tcp 2>/dev/null || true
    ufw allow "$ARTICA_PROXY_PORT"/tcp 2>/dev/null || true
    ufw allow 8080/tcp 2>/dev/null || true
    ufw allow 8443/tcp 2>/dev/null || true
fi

if command -v firewall-cmd >/dev/null 2>&1; then
    firewall-cmd --permanent --add-port="${ARTICA_HTTP_PORT}/tcp" 2>/dev/null || true
    firewall-cmd --permanent --add-port="${ARTICA_HTTPS_PORT}/tcp" 2>/dev/null || true
    firewall-cmd --permanent --add-port="${ARTICA_PROXY_PORT}/tcp" 2>/dev/null || true
    firewall-cmd --permanent --add-port=8080/tcp 2>/dev/null || true
    firewall-cmd --permanent --add-port=8443/tcp 2>/dev/null || true
    firewall-cmd --reload 2>/dev/null || true
fi

echo
printf "✅ Artica a été préparé sur le système.\n"
printf "Service: %s\n" "${ARTICA_SERVICE}"
printf "Interface web: http://%s:%s\n" "$(hostname -I | awk '{print $1}')" "${ARTICA_HTTP_PORT}"
printf "Documentation: adaptez l'URL du dépôt officiel Artica selon votre distribution et votre version.\n"
