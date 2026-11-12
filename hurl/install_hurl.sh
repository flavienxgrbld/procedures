#!/usr/bin/env bash
# Installation de Hurl (outil de test HTTP d'Orange) avec le paquet .deb officiel.
#
# Variables modifiables :
#   HURL_VERSION  version à installer (défaut : dernière publiée)

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

info "Hurl - Tests HTTP en fichiers texte"

[ "$PKG_MANAGER" = "apt" ] || error_exit "Paquet .deb seulement : sur les autres systèmes, utiliser l'archive tar.gz de la page des versions"

case "$(dpkg --print-architecture)" in
    amd64|arm64) ARCH="$(dpkg --print-architecture)" ;;
    *) error_exit "Architecture non gérée : $(dpkg --print-architecture)" ;;
esac

pkg_install curl ca-certificates
HURL_VERSION="${HURL_VERSION:-$(github_latest_tag Orange-OpenSource/hurl 8.1.0)}"
DEB="hurl_${HURL_VERSION}_${ARCH}.deb"
download_file "https://github.com/Orange-OpenSource/hurl/releases/download/${HURL_VERSION}/${DEB}" "/tmp/${DEB}"
add_temp_file "/tmp/${DEB}"
DEBIAN_FRONTEND=noninteractive apt-get install -y "/tmp/${DEB}"

echo
echo "✅ $(hurl --version | head -n1)"
echo "Test : hurl --test fichier.hurl (aucun droit root nécessaire)"
