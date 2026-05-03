#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "InfluxDB - Base de données temporelles"

INFLUXDB_VERSION="2.x"

echo "=== Installation d'InfluxDB ==="
case "$PKG_MANAGER" in
    apt)
        echo "deb [signed-by=/usr/share/keyrings/influxdb-archive-keyring.gpg] https://repos.influxdata.com/debian stable main" | tee /etc/apt/sources.list.d/influxdata.list
        wget -q https://repos.influxdata.com/influxdata-archive-keyring.gpg -O /tmp/influxdb-keyring.gpg && apt-key add /tmp/influxdb-keyring.gpg && rm /tmp/influxdb-keyring.gpg
        pkg_update
        pkg_install influxdb2
        ;;
    dnf|yum)
        cat > /etc/yum.repos.d/influxdb.repo <<'EOF'
[influxdb]
name = InfluxData Repository - RHEL
baseurl = https://repos.influxdata.com/rhel/
enabled = 1
gpgkey = https://repos.influxdata.com/influxdata-archive.key
gpgcheck = 1
EOF
        pkg_install influxdb2
        ;;
esac

systemctl enable influxdb
systemctl start influxdb

if command -v ufw >/dev/null 2>&1; then
    ufw allow 8086/tcp
fi

echo
echo "✅ InfluxDB installé avec succès"
echo "URL: http://votre-serveur:8086"
echo "Port: 8086"
