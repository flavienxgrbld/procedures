#!/usr/bin/env bash
# Installation de Certbot (Let's Encrypt) avec l'extension du serveur web présent,
# et activation du renouvellement automatique.
#
# Variables facultatives (obtention immédiate d'un certificat) :
#   CERTBOT_DOMAIN  nom de domaine public pointant vers ce serveur (plusieurs : séparés par des virgules)
#   CERTBOT_EMAIL   adresse de contact pour Let's Encrypt (obligatoire avec CERTBOT_DOMAIN)

set -euo pipefail

# Bibliothèque commune : copie du dépôt en priorité, téléchargement sinon.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SCRIPT="${SCRIPT_DIR}/../install_common.sh"
if [ ! -f "$COMMON_SCRIPT" ]; then
    COMMON_SCRIPT="$(mktemp)"
    curl -fsSL "https://raw.githubusercontent.com/flavienxgrbld/procedures/main/install_common.sh" -o "$COMMON_SCRIPT"
fi
# shellcheck source=../install_common.sh
source "$COMMON_SCRIPT"

ensure_root
detect_os
detect_package_manager

info "Certbot - Certificats TLS Let's Encrypt"

# Extension adaptée au serveur web déjà installé (installer les deux ajouterait
# Apache ET Nginx, qui se disputeraient le port 80).
PLUGIN=""
if command -v nginx >/dev/null 2>&1; then
    PLUGIN="nginx"
elif command -v apache2 >/dev/null 2>&1 || command -v httpd >/dev/null 2>&1; then
    PLUGIN="apache"
fi
info "Serveur web détecté : ${PLUGIN:-aucun (mode standalone)}"

pkg_update
case "$PKG_MANAGER" in
    apt)
        pkgs=(certbot)
        [ -n "$PLUGIN" ] && pkgs+=("python3-certbot-${PLUGIN}")
        ;;
    dnf|yum)
        if is_redhat_family && [ "$OS_ID" != "fedora" ]; then
            pkg_install epel-release || warn "EPEL non installé : certbot pourrait être introuvable"
        fi
        pkgs=(certbot)
        [ -n "$PLUGIN" ] && pkgs+=("python3-certbot-${PLUGIN}")
        ;;
    zypper)
        pkgs=(python3-certbot)
        [ -n "$PLUGIN" ] && pkgs+=("python3-certbot-${PLUGIN}")
        ;;
    pacman)
        pkgs=(certbot)
        [ -n "$PLUGIN" ] && pkgs+=("certbot-${PLUGIN}")
        ;;
esac
pkg_install "${pkgs[@]}"
certbot --version

info "Renouvellement automatique"
TIMER=""
for t in certbot.timer certbot-renew.timer snap.certbot.renew.timer; do
    if systemctl list-unit-files "$t" >/dev/null 2>&1 && systemctl list-unit-files "$t" | grep -q "^$t"; then
        TIMER="$t"; break
    fi
done
if [ -n "$TIMER" ]; then
    systemctl enable --now "$TIMER"
    info "Minuteur actif : $TIMER"
else
    warn "Aucun minuteur systemd fourni par le paquet : ajout d'une tâche cron quotidienne"
    echo "17 3 * * * root certbot renew --quiet" > /etc/cron.d/certbot-renew
fi

if [ -n "${CERTBOT_DOMAIN:-}" ]; then
    [ -n "${CERTBOT_EMAIL:-}" ] || error_exit "CERTBOT_EMAIL est obligatoire avec CERTBOT_DOMAIN"
    info "Demande du certificat pour ${CERTBOT_DOMAIN}"
    if [ -n "$PLUGIN" ]; then
        certbot "--${PLUGIN}" -d "$CERTBOT_DOMAIN" -m "$CERTBOT_EMAIL" --agree-tos --non-interactive --redirect
    else
        certbot certonly --standalone -d "$CERTBOT_DOMAIN" -m "$CERTBOT_EMAIL" --agree-tos --non-interactive
    fi
    certbot renew --dry-run
fi

echo
echo "✅ Certbot installé"
if [ -z "${CERTBOT_DOMAIN:-}" ]; then
    echo "Obtenir un certificat :"
    if [ -n "$PLUGIN" ]; then
        echo "  sudo certbot --${PLUGIN} -d votre-domaine.fr"
    else
        echo "  sudo certbot certonly --standalone -d votre-domaine.fr   (port 80 libre requis)"
    fi
fi
echo "Tester le renouvellement : sudo certbot renew --dry-run"
