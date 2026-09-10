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

info "FOG Project - Serveur de déploiement / imaging" 

FOG_REPO_URL="${FOG_REPO_URL:-https://github.com/FOGProject/fogproject.git}"
FOG_INSTALLER="${FOG_INSTALLER:-bin/installfog.sh}"
FOG_BASE_DIR="${FOG_BASE_DIR:-/opt/fogproject}"

case "$PKG_MANAGER" in
    apt)
        pkg_install ca-certificates curl gnupg wget git tar gzip lsb-release
        ;;
    dnf|yum)
        pkg_install ca-certificates curl gnupg wget git tar gzip
        ;;
    zypper)
        pkg_install ca-certificates curl gnupg wget git tar gzip
        ;;
    pacman)
        pkg_install ca-certificates curl gnupg wget git tar gzip
        ;;
    *)
        fatal "Gestionnaire de paquets non supporté pour FOG Project : $PKG_MANAGER"
        ;;
esac

echo "=== Préparation du serveur FOG ==="

if [ ! -d "$FOG_BASE_DIR" ]; then
    git clone "$FOG_REPO_URL" "$FOG_BASE_DIR"
else
    warn "Le dossier $FOG_BASE_DIR existe déjà. Vérification du dépôt local."
    git -C "$FOG_BASE_DIR" pull --ff-only 2>/dev/null || true
fi

if [ ! -f "$FOG_BASE_DIR/$FOG_INSTALLER" ]; then
    fatal "Le script d'installation FOG n'a pas été trouvé dans $FOG_BASE_DIR. Vérifiez le dépôt officiel et la version utilisée."
fi

echo "=== Configuration du réseau et des services ==="
warn "FOG Project nécessite souvent une IP statique, DHCP et PXE correctement configurés."
warn "Le serveur devra être validé via le script d'installation officiel du projet."

if command -v ufw >/dev/null 2>&1; then
    ufw allow 80/tcp 2>/dev/null || true
    ufw allow 443/tcp 2>/dev/null || true
    ufw allow 67/udp 2>/dev/null || true
    ufw allow 69/udp 2>/dev/null || true
fi

if command -v firewall-cmd >/dev/null 2>&1; then
    firewall-cmd --permanent --add-port=80/tcp 2>/dev/null || true
    firewall-cmd --permanent --add-port=443/tcp 2>/dev/null || true
    firewall-cmd --permanent --add-port=67/udp 2>/dev/null || true
    firewall-cmd --permanent --add-port=69/udp 2>/dev/null || true
    firewall-cmd --reload 2>/dev/null || true
fi

echo "=== Lancement de l'installateur FOG ==="
cd "$FOG_BASE_DIR"
if [ -x "$FOG_BASE_DIR/$FOG_INSTALLER" ]; then
    bash "$FOG_BASE_DIR/$FOG_INSTALLER"
else
    warn "Le script d'installation n'est pas exécutable. Tentative d'exécution via bash."
    bash "$FOG_BASE_DIR/$FOG_INSTALLER"
fi

echo
printf "✅ Préparation FOG Project terminée.\n"
printf "Répertoire source: %s\n" "$FOG_BASE_DIR"
printf "Le script officiel de FOG a été lancé.\n"
printf "Vérifiez le réseau PXE/DHCP et l'interface web avant déploiement.\n"
