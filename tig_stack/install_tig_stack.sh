#!/usr/bin/env bash
# Pile TIG : InfluxDB 2 + Telegraf + Grafana (dépôts officiels), entièrement reliée :
# InfluxDB configuré, Telegraf écrit dans InfluxDB avec un jeton dédié, Grafana prêt
# avec la source de données InfluxDB déclarée.

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

info "Pile TIG - Telegraf, InfluxDB, Grafana"

ORG="labo"; BUCKET="telegraf"
INFLUX_PASS="$(random_password 20)"

pkg_update
pkg_install curl gnupg ca-certificates jq
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://repos.influxdata.com/influxdata-archive.key | gpg --dearmor --yes -o /etc/apt/keyrings/influxdata-archive.gpg
echo "deb [signed-by=/etc/apt/keyrings/influxdata-archive.gpg] https://repos.influxdata.com/debian stable main" > /etc/apt/sources.list.d/influxdata.list
grafana_repo
pkg_install influxdb2 influxdb2-cli telegraf grafana

systemctl enable influxdb; systemctl restart influxdb
for _ in $(seq 1 30); do curl -fsS http://127.0.0.1:8086/health >/dev/null 2>&1 && break; sleep 2; done

if curl -fsS http://127.0.0.1:8086/api/v2/setup | grep -q '"allowed": *true'; then
    info "Configuration initiale d'InfluxDB"
    influx setup --host http://127.0.0.1:8086 --username admin --password "$INFLUX_PASS" \
        --org "$ORG" --bucket "$BUCKET" --retention 30d --force
    BUCKET_ID="$(influx bucket list --org "$ORG" --name "$BUCKET" --json | jq -r '.[0].id')"
    TG_TOKEN="$(influx auth create --org "$ORG" --write-bucket "$BUCKET_ID" --description telegraf --json | jq -r '.token')"
    GF_TOKEN="$(influx auth create --org "$ORG" --read-bucket "$BUCKET_ID" --description grafana --json | jq -r '.token')"

    info "Telegraf -> InfluxDB 2"
    backup_file /etc/telegraf/telegraf.conf
    mkdir -p /etc/telegraf/telegraf.d
    # Désactiver la sortie InfluxDB 1.x du fichier d'origine
    sed -i 's/^\[\[outputs\.influxdb\]\]/# [[outputs.influxdb]]/' /etc/telegraf/telegraf.conf
    cat > /etc/telegraf/telegraf.d/influxdb_v2.conf <<EOF
[[outputs.influxdb_v2]]
  urls = ["http://127.0.0.1:8086"]
  token = "${TG_TOKEN}"
  organization = "${ORG}"
  bucket = "${BUCKET}"
EOF
    chown root:telegraf /etc/telegraf/telegraf.d/influxdb_v2.conf; chmod 640 /etc/telegraf/telegraf.d/influxdb_v2.conf

    info "Grafana : source de données InfluxDB (Flux)"
    cat > /etc/grafana/provisioning/datasources/influxdb.yaml <<EOF
apiVersion: 1
datasources:
  - name: InfluxDB
    type: influxdb
    access: proxy
    url: http://127.0.0.1:8086
    jsonData:
      version: Flux
      organization: ${ORG}
      defaultBucket: ${BUCKET}
    secureJsonData:
      token: ${GF_TOKEN}
EOF
    chown root:grafana /etc/grafana/provisioning/datasources/influxdb.yaml; chmod 640 /etc/grafana/provisioning/datasources/influxdb.yaml
    save_credentials /root/tig_identifiants.txt \
        "InfluxDB : http://<serveur>:8086 — admin / ${INFLUX_PASS} (organisation ${ORG})" \
        "Grafana  : http://<serveur>:3000 — admin / admin (changement imposé à la première connexion)"
else
    warn "InfluxDB est déjà configuré : liaisons Telegraf/Grafana non modifiées"
fi

for s in telegraf grafana-server; do systemctl enable "$s"; systemctl restart "$s"; done
for s in influxdb telegraf grafana-server; do check_service_status "$s"; done
LAN="$(ip -4 route show scope link 2>/dev/null | awk '!/docker|br-|veth/ {print $1; exit}')" || true
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active" && [ -n "$LAN" ]; then
    ufw allow from "$LAN" to any port 3000 proto tcp >/dev/null
    ufw allow from "$LAN" to any port 8086 proto tcp >/dev/null
fi

echo
echo "✅ Pile TIG installée : Grafana http://$(primary_ip):3000 (admin / admin, à changer)"
echo "Les métriques du serveur arrivent dans le bucket ${BUCKET} ; identifiants : /root/tig_identifiants.txt"
