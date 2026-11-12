#!/usr/bin/env bash
# Installation d'InfluxDB 2 et de son client (dépôt officiel InfluxData),
# avec la configuration initiale faite immédiatement (compte admin, organisation, bucket).
#
# Variables modifiables :
#   INFLUX_USER / INFLUX_PASS  compte administrateur (défaut : admin / généré)
#   INFLUX_ORG                 organisation (défaut : labo)
#   INFLUX_BUCKET              premier bucket (défaut : metriques)
#   INFLUX_RETENTION           durée de conservation (défaut : 30d)

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

info "InfluxDB 2 - Base de séries temporelles"

INFLUX_USER="${INFLUX_USER:-admin}"
INFLUX_PASS="${INFLUX_PASS:-$(random_password 20)}"
INFLUX_ORG="${INFLUX_ORG:-labo}"
INFLUX_BUCKET="${INFLUX_BUCKET:-metriques}"
INFLUX_RETENTION="${INFLUX_RETENTION:-30d}"

info "Dépôt InfluxData"
case "$PKG_MANAGER" in
    apt)
        pkg_update
        pkg_install curl gnupg ca-certificates
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://repos.influxdata.com/influxdata-archive.key | gpg --dearmor --yes -o /etc/apt/keyrings/influxdata-archive.gpg
        echo "deb [signed-by=/etc/apt/keyrings/influxdata-archive.gpg] https://repos.influxdata.com/debian stable main" \
            > /etc/apt/sources.list.d/influxdata.list
        pkg_update
        ;;
    dnf|yum)
        cat > /etc/yum.repos.d/influxdata.repo <<'EOF'
[influxdata]
name = InfluxData Repository - Stable
baseurl = https://repos.influxdata.com/stable/$basearch/main
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdata-archive.key
EOF
        ;;
    *) error_exit "Dépôt InfluxData disponible pour apt et dnf/yum seulement" ;;
esac

pkg_install influxdb2 influxdb2-cli
systemctl enable influxdb
systemctl restart influxdb

info "Attente de l'API (port 8086)"
for _ in $(seq 1 30); do
    curl -fsS http://127.0.0.1:8086/health >/dev/null 2>&1 && break
    sleep 2
done
curl -fsS http://127.0.0.1:8086/health >/dev/null || error_exit "InfluxDB ne répond pas sur le port 8086"

if influx ping >/dev/null 2>&1 && curl -fsS http://127.0.0.1:8086/api/v2/setup | grep -q '"allowed": *false'; then
    warn "InfluxDB est déjà configuré : configuration initiale ignorée"
    SETUP_DONE=0
else
    info "Configuration initiale (empêche un tiers de créer le premier compte administrateur)"
    influx setup --host http://127.0.0.1:8086 \
        --username "$INFLUX_USER" --password "$INFLUX_PASS" \
        --org "$INFLUX_ORG" --bucket "$INFLUX_BUCKET" --retention "$INFLUX_RETENTION" --force
    SETUP_DONE=1
fi

open_ports 8086/tcp

if [ "$SETUP_DONE" = 1 ]; then
    save_credentials /root/influxdb_identifiants.txt \
        "Interface     : http://<serveur>:8086" \
        "Compte        : ${INFLUX_USER}" \
        "Mot de passe  : ${INFLUX_PASS}" \
        "Organisation  : ${INFLUX_ORG} — bucket : ${INFLUX_BUCKET}" \
        "Jeton admin   : enregistré dans la configuration du client influx de root (influx auth list)"
fi

echo
echo "✅ InfluxDB installé : http://$(primary_ip):8086"
echo "Jeton pour Telegraf : sudo influx auth create --org ${INFLUX_ORG} --write-buckets --read-buckets --description telegraf"
