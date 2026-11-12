#!/usr/bin/env bash
# Installation de Prometheus et node_exporter (binaires officiels, dernières versions)
# en services systemd, configuration dans /etc/prometheus.
#
# Variables modifiables :
#   PROM_TARGETS  autres machines avec node_exporter, ex. "192.168.1.21:9100 192.168.1.22:9100"

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

info "Prometheus + node_exporter"
command -v systemctl >/dev/null 2>&1 || error_exit "systemd est requis"

case "$(uname -m)" in x86_64) ARCH=amd64 ;; aarch64|arm64) ARCH=arm64 ;; armv7l) ARCH=armv7 ;; *) error_exit "Architecture non gérée" ;; esac
pkg_install curl tar

fetch_release() {  # fetch_release depot nom version -> extrait dans $WORK/nom-version.linux-ARCH
    local repo="$1" name="$2" ver="$3" pkg
    pkg="${name}-${ver}.linux-${ARCH}"
    download_file "https://github.com/${repo}/releases/download/v${ver}/${pkg}.tar.gz" "${WORK}/${pkg}.tar.gz"
    download_file "https://github.com/${repo}/releases/download/v${ver}/sha256sums.txt" "${WORK}/${name}.sha256"
    (cd "$WORK" && grep " ${pkg}.tar.gz\$" "${name}.sha256" | sha256sum -c -) || error_exit "Somme de contrôle invalide : ${pkg}"
    tar -xzf "${WORK}/${pkg}.tar.gz" -C "$WORK"
    echo "${WORK}/${pkg}"
}

WORK="$(mktemp -d)"; add_temp_file "$WORK"
PROM_VER="$(github_latest_tag prometheus/prometheus v3.16.0)"; PROM_VER="${PROM_VER#v}"
NE_VER="$(github_latest_tag prometheus/node_exporter v1.12.1)"; NE_VER="${NE_VER#v}"

for u in prometheus node_exporter; do
    id "$u" >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin "$u"
done
mkdir -p /etc/prometheus /var/lib/prometheus

info "Prometheus ${PROM_VER}"
D="$(fetch_release prometheus/prometheus prometheus "$PROM_VER")"
install -m 0755 "${D}/prometheus" "${D}/promtool" /usr/local/bin/

info "node_exporter ${NE_VER}"
D="$(fetch_release prometheus/node_exporter node_exporter "$NE_VER")"
install -m 0755 "${D}/node_exporter" /usr/local/bin/

if [ ! -f /etc/prometheus/prometheus.yml ]; then
    targets='"localhost:9100"'
    for t in ${PROM_TARGETS:-}; do targets+=", \"${t}\""; done
    cat > /etc/prometheus/prometheus.yml <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: serveurs
    static_configs:
      - targets: [${targets}]
EOF
else
    info "Configuration existante conservée : /etc/prometheus/prometheus.yml"
fi
chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
promtool check config /etc/prometheus/prometheus.yml

cat > /etc/systemd/system/prometheus.service <<'EOF'
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
ExecStart=/usr/local/bin/prometheus \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/var/lib/prometheus \
    --storage.tsdb.retention.time=30d
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
cat > /etc/systemd/system/node_exporter.service <<'EOF'
[Unit]
Description=Prometheus node_exporter
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
ExecStart=/usr/local/bin/node_exporter
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
for s in node_exporter prometheus; do systemctl enable "$s"; systemctl restart "$s"; done
sleep 2
check_service_status prometheus
check_service_status node_exporter

LAN="$(ip -4 route show scope link 2>/dev/null | awk '!/docker|br-|veth/ {print $1; exit}')" || true
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active" && [ -n "$LAN" ]; then
    ufw allow from "$LAN" to any port 9090 proto tcp >/dev/null
    ufw allow from "$LAN" to any port 9100 proto tcp >/dev/null
fi

echo
echo "✅ Prometheus ${PROM_VER} et node_exporter ${NE_VER} installés"
echo "Interface : http://$(primary_ip):9090 (Status > Targets)"
