#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "Certbot - Génération de certificats SSL/TLS Let's Encrypt"

echo "=== Mise à jour du système ==="
pkg_update
pkg_upgrade

echo "=== Installation de Certbot ==="
case "$PKG_MANAGER" in
    apt)
        pkg_install certbot python3-certbot-apache python3-certbot-nginx
        ;;
    dnf|yum)
        pkg_install certbot python3-certbot-apache python3-certbot-nginx
        ;;
    zypper)
        pkg_install certbot python3-certbot-nginx
        ;;
    pacman)
        pkg_install certbot certbot-apache certbot-nginx
        ;;
esac

# Vérification installation
certbot --version

# Configuration renouvellement automatique
if command -v systemctl >/dev/null 2>&1; then
    systemctl enable certbot.timer 2>/dev/null || true
    systemctl start certbot.timer 2>/dev/null || true
fi

echo
echo "✅ Certbot installé avec succès"
echo "Commande pour obtenir un certificat:"
echo "  certbot certonly --standalone -d votre-domaine.com"
echo "  certbot certonly --apache -d votre-domaine.com"
echo "  certbot certonly --nginx -d votre-domaine.com"
