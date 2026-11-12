#!/usr/bin/env bash
# Installation du courtier MQTT Mosquitto avec authentification par mot de passe.
#
# Variables modifiables :
#   MQTT_USER / MQTT_PASS  premier compte (défaut : domotique / généré)
#   MQTT_WEBSOCKET         oui pour ouvrir aussi MQTT sur WebSocket, port 9001 (défaut : non)

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

info "Mosquitto - Courtier MQTT"

MQTT_USER="${MQTT_USER:-domotique}"
MQTT_PASS="${MQTT_PASS:-$(random_password 20)}"
MQTT_WEBSOCKET="${MQTT_WEBSOCKET:-non}"
PASSWD=/etc/mosquitto/passwd

pkg_update
case "$PKG_MANAGER" in
    apt) pkg_install mosquitto mosquitto-clients ;;
    dnf|yum) pkg_install epel-release 2>/dev/null || true; pkg_install mosquitto ;;
    *) pkg_install mosquitto ;;
esac

mkdir -p /etc/mosquitto/conf.d
grep -q '^include_dir /etc/mosquitto/conf.d' /etc/mosquitto/mosquitto.conf \
    || echo "include_dir /etc/mosquitto/conf.d" >> /etc/mosquitto/mosquitto.conf

if [ -f "$PASSWD" ]; then
    mosquitto_passwd -b "$PASSWD" "$MQTT_USER" "$MQTT_PASS"
else
    mosquitto_passwd -c -b "$PASSWD" "$MQTT_USER" "$MQTT_PASS"
fi
chown root:mosquitto "$PASSWD"
chmod 640 "$PASSWD"

{
    echo "# Généré par install_mosquitto.sh"
    echo "listener 1883"
    echo "allow_anonymous false"
    echo "password_file ${PASSWD}"
    if [ "$MQTT_WEBSOCKET" = "oui" ]; then
        echo
        echo "listener 9001"
        echo "protocol websockets"
    fi
} > /etc/mosquitto/conf.d/local.conf

systemctl enable mosquitto
systemctl restart mosquitto
check_service_status mosquitto

LAN="$(ip -4 route show scope link 2>/dev/null | awk '!/docker|br-|veth/ {print $1; exit}')" || true
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active" && [ -n "$LAN" ]; then
    ufw allow from "$LAN" to any port 1883 proto tcp >/dev/null
    [ "$MQTT_WEBSOCKET" = "oui" ] && ufw allow from "$LAN" to any port 9001 proto tcp >/dev/null
fi

save_credentials /root/mosquitto_identifiants.txt "Compte MQTT : ${MQTT_USER}" "Mot de passe : ${MQTT_PASS}"
echo
echo "✅ Mosquitto installé (port 1883, authentification obligatoire)"
echo "Ajouter un compte : sudo mosquitto_passwd ${PASSWD} capteur1 && sudo systemctl restart mosquitto"
echo "Test : mosquitto_sub -h localhost -u ${MQTT_USER} -P <mot de passe> -t 'test/#'"
