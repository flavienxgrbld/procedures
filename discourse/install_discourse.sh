#!/usr/bin/env bash
# Installation de Discourse avec la méthode officielle (discourse_docker + discourse-setup).
# L'assistant officiel pose ensuite ses questions (nom d'hôte, e-mail, SMTP).

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

info "Discourse - Forum de discussion"

DISCOURSE_DIR="/var/discourse"

mem_mb=$(awk '/MemTotal/{print int($2/1024)}' /proc/meminfo)
if [ "$mem_mb" -lt 1900 ]; then
    warn "Mémoire : ${mem_mb} Mo. Discourse demande 2 Go (ou 1 Go avec swap) ; discourse-setup créera une swap si besoin."
fi

pkg_update
pkg_install git curl

if ! command -v docker >/dev/null 2>&1; then
    info "Installation de Docker avec le script officiel get.docker.com"
    DOCKER_SH="$(mktemp)"
    add_temp_file "$DOCKER_SH"
    download_file https://get.docker.com "$DOCKER_SH"
    sh "$DOCKER_SH"
fi
systemctl enable --now docker

if [ -d "${DISCOURSE_DIR}/.git" ]; then
    info "Mise à jour de ${DISCOURSE_DIR}"
    git -C "$DISCOURSE_DIR" pull --ff-only
else
    info "Récupération de discourse_docker dans ${DISCOURSE_DIR}"
    git clone https://github.com/discourse/discourse_docker.git "$DISCOURSE_DIR"
fi
chmod 700 "${DISCOURSE_DIR}/containers"

open_ports 80/tcp 443/tcp

info "Lancement de l'assistant officiel discourse-setup"
cd "$DISCOURSE_DIR"
./discourse-setup

echo
echo "✅ Discourse installé"
echo "Commandes de maintenance : cd ${DISCOURSE_DIR} && sudo ./launcher rebuild app"
