#!/usr/bin/env bash
# Installation de Duplicati 2 (paquet officiel sans interface graphique) avec son
# serveur web en service systemd.
#
# Variables modifiables :
#   DUPLICATI_PASSWORD  mot de passe de l'interface web (défaut : généré)
#   DUPLICATI_LISTEN    loopback (défaut, accès local seulement) ou any (accès réseau)

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

info "Duplicati - Sauvegardes chiffrées et incrémentales"

DUPLICATI_PASSWORD="${DUPLICATI_PASSWORD:-$(random_password 20)}"
DUPLICATI_LISTEN="${DUPLICATI_LISTEN:-loopback}"
case "$DUPLICATI_LISTEN" in loopback|any) ;; *) error_exit "DUPLICATI_LISTEN doit valoir loopback ou any" ;; esac

case "$(uname -m)" in
    x86_64) ARCH="x64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    armv7l) ARCH="arm7" ;;
    *) error_exit "Architecture non gérée : $(uname -m)" ;;
esac
case "$PKG_MANAGER" in
    apt) EXT="deb" ;;
    dnf|yum|zypper) EXT="rpm" ;;
    *) error_exit "Paquet Duplicati disponible en .deb et .rpm seulement" ;;
esac

pkg_install curl ca-certificates

info "Recherche du dernier paquet stable (linux-${ARCH}-cli.${EXT})"
PKG_URL=$(curl -fsSL "https://api.github.com/repos/duplicati/duplicati/releases/latest" \
    | grep -oE "https://[^\"]+-linux-${ARCH}-cli\.${EXT}" | head -n1) || true
[ -n "$PKG_URL" ] || error_exit "Paquet introuvable : télécharger le fichier à la main sur https://duplicati.com/download"
info "Paquet : ${PKG_URL##*/}"

PKG_FILE="/tmp/${PKG_URL##*/}"
add_temp_file "$PKG_FILE"
download_file "$PKG_URL" "$PKG_FILE"
case "$PKG_MANAGER" in
    apt) DEBIAN_FRONTEND=noninteractive apt-get install -y "$PKG_FILE" ;;
    dnf|yum) "$PKG_MANAGER" install -y "$PKG_FILE" ;;
    zypper) zypper --non-interactive install --allow-unsigned-rpm "$PKG_FILE" ;;
esac

command -v duplicati-server >/dev/null 2>&1 \
    || error_exit "duplicati-server absent du paquet installé : installer le paquet linux-${ARCH}-gui.${EXT} à la place"

if [ "$EXT" = "deb" ]; then OPTS_FILE="/etc/default/duplicati"; else OPTS_FILE="/etc/sysconfig/duplicati"; fi

if ! systemctl list-unit-files duplicati.service 2>/dev/null | grep -q '^duplicati.service'; then
    warn "Le paquet ne fournit pas duplicati.service : création du service"
    cat > /etc/systemd/system/duplicati.service <<EOF
[Unit]
Description=Duplicati web-server
After=network.target

[Service]
Nice=19
IOSchedulingClass=idle
EnvironmentFile=-${OPTS_FILE}
ExecStart=$(command -v duplicati-server) \$DAEMON_OPTS
Restart=always

[Install]
WantedBy=multi-user.target
EOF
fi

info "Options du serveur dans ${OPTS_FILE} (écoute : ${DUPLICATI_LISTEN})"
backup_file "$OPTS_FILE"
(umask 077; cat > "$OPTS_FILE") <<EOF
# Options passées à duplicati-server (fichier généré par install_duplicati.sh)
DAEMON_OPTS="--webservice-interface=${DUPLICATI_LISTEN} --webservice-port=8200 --webservice-password=${DUPLICATI_PASSWORD}"
EOF
chmod 600 "$OPTS_FILE"

systemctl daemon-reload
systemctl enable duplicati.service
systemctl restart duplicati.service
sleep 3
check_service_status duplicati

[ "$DUPLICATI_LISTEN" = "any" ] && open_ports 8200/tcp

save_credentials /root/duplicati_identifiants.txt "Interface Duplicati : port 8200" "Mot de passe        : ${DUPLICATI_PASSWORD}"

echo
echo "✅ Duplicati installé (${PKG_URL##*/})"
if [ "$DUPLICATI_LISTEN" = "any" ]; then
    echo "Interface : http://$(hostname -I | awk '{print $1}'):8200"
else
    echo "Interface : http://127.0.0.1:8200 (depuis un autre poste : ssh -L 8200:127.0.0.1:8200 <serveur>)"
fi
echo "Mot de passe : /root/duplicati_identifiants.txt"
