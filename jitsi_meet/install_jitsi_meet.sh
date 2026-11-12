#!/usr/bin/env bash
# Installation de Jitsi Meet (dépôt officiel) sur Debian 12/13 ou Ubuntu 22.04/24.04,
# sans question grâce à la préconfiguration debconf.
#
# Variables :
#   JITSI_HOST   nom de domaine public du serveur, ex. visio.exemple.fr (obligatoire)
#   JITSI_EMAIL  e-mail pour Let's Encrypt ; sans lui, certificat autosigné

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
is_debian_family || error_exit "Ce script est prévu pour Debian ou Ubuntu"

info "Jitsi Meet - Visioconférence"

[ -n "${JITSI_HOST:-}" ] || error_exit "Définir JITSI_HOST, ex. : sudo JITSI_HOST=visio.exemple.fr JITSI_EMAIL=admin@exemple.fr bash install_jitsi_meet.sh"

info "Nom d'hôte : ${JITSI_HOST}"
hostnamectl set-hostname "$JITSI_HOST"
grep -qE "[[:space:]]${JITSI_HOST}([[:space:]]|\$)" /etc/hosts || echo "127.0.0.1 ${JITSI_HOST}" >> /etc/hosts

pkg_update
pkg_install curl gnupg2 apt-transport-https ca-certificates nginx-full debconf-utils lsb-release
install -m 0755 -d /etc/apt/keyrings

info "Dépôt Jitsi"
curl -fsSL https://download.jitsi.org/jitsi-key.gpg.key | gpg --dearmor --yes -o /etc/apt/keyrings/jitsi-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/" > /etc/apt/sources.list.d/jitsi-stable.list

if is_ubuntu; then
    info "Dépôt Prosody (version récente requise sur Ubuntu)"
    curl -fsSL https://prosody.im/files/prosody-debian-packages.key | gpg --dearmor --yes -o /etc/apt/keyrings/prosody-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/prosody-keyring.gpg] http://packages.prosody.im/debian $(lsb_release -sc) main" > /etc/apt/sources.list.d/prosody.list
    pkg_install lua5.2
fi
pkg_update

info "Préconfiguration (nom d'hôte, certificat)"
if [ -n "${JITSI_EMAIL:-}" ]; then
    CERT_CHOICE="Let's Encrypt certificates"
else
    CERT_CHOICE="Generate a new self-signed certificate"
    warn "JITSI_EMAIL absent : certificat autosigné (avertissement dans les navigateurs)"
fi
debconf-set-selections <<EOF
jitsi-videobridge2 jitsi-videobridge/jvb-hostname string ${JITSI_HOST}
jitsi-meet-web-config jitsi-meet/cert-choice select ${CERT_CHOICE}
jitsi-meet-web-config jitsi-meet/email string ${JITSI_EMAIL:-}
jitsi-meet-web-config jitsi-meet/jaas-choice boolean false
EOF

open_ports 80/tcp 443/tcp 10000/udp
info "Installation de Jitsi Meet"
pkg_install jitsi-meet

for svc in prosody jicofo jitsi-videobridge2 nginx; do
    check_service_status "$svc"
done

echo
echo "✅ Jitsi Meet installé : https://${JITSI_HOST}"
echo "Par défaut, n'importe qui peut créer une réunion : voir « Réserver la création de salles » dans le README."
