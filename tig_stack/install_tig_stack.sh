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

info "Telemetry Dashboard - TIG Stack (Telegraf, InfluxDB, Grafana)"

echo "=== Installation complète du TIG Stack ==="
pkg_install curl

# Installation InfluxDB
echo "Installation d'InfluxDB..."
case "$PKG_MANAGER" in
    apt)
        wget -q https://repos.influxdata.com/influxdata-archive-keyring.gpg && apt-key add influxdata-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/influxdb-archive-keyring.gpg] https://repos.influxdata.com/debian stable main" | tee /etc/apt/sources.list.d/influxdata.list
        pkg_update
        pkg_install influxdb2 telegraf
        ;;
    dnf|yum)
        cat > /etc/yum.repos.d/influxdb.repo <<'EOF'
[influxdb]
name = InfluxData Repository
baseurl = https://repos.influxdata.com/rhel
enabled = 1
gpgkey = https://repos.influxdata.com/influxdata-archive.key
EOF
        pkg_install influxdb2 telegraf
        ;;
esac

# Installation Grafana (voir install_grafana.sh)
echo "Installation de Grafana..."
case "$PKG_MANAGER" in
    apt)
        apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 16122900
        echo "deb https://packages.grafana.com/oss/deb stable main" | tee /etc/apt/sources.list.d/grafana.list
        pkg_update
        pkg_install grafana
        ;;
    dnf|yum)
        cat > /etc/yum.repos.d/grafana.repo <<'EOF'
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgkey=https://rpm.grafana.com/pubkey.asc
gpgcheck=1
EOF
        pkg_install grafana
        ;;
esac

# Démarrage services
systemctl enable influxdb telegraf grafana-server
systemctl start influxdb telegraf grafana-server

echo
echo "✅ TIG Stack en cours d'installation"
echo "Grafana: http://votre-serveur:3000"
echo "InfluxDB: http://votre-serveur:8086"
echo "Telegraf collecte les métriques système"
