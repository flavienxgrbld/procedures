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

info "Elastic Stack (ELK) - Logging et analytics"

echo "=== Installation d'Elasticsearch ==="
pkg_install openjdk-11-jre curl

case "$PKG_MANAGER" in
    apt)
        wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
        echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list
        pkg_update
        pkg_install elasticsearch kibana logstash filebeat
        ;;
    dnf|yum)
        rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
        echo '[elastic-7.x]
name=Elastic repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md' | tee /etc/yum.repos.d/elastic.repo
        pkg_install elasticsearch kibana logstash filebeat
        ;;
esac

systemctl enable elasticsearch kibana
systemctl start elasticsearch kibana

if command -v ufw >/dev/null 2>&1; then
    ufw allow 9200/tcp  # Elasticsearch
    ufw allow 5601/tcp  # Kibana
    ufw allow 5000/tcp  # Logstash
fi

echo
echo "✅ Elastic Stack en cours d'installation"
echo "Elasticsearch: http://votre-serveur:9200"
echo "Kibana: http://votre-serveur:5601"
