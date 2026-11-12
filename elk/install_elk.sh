#!/usr/bin/env bash
# Installation d'Elasticsearch et Kibana (sécurité activée), et en option Logstash,
# depuis le dépôt officiel Elastic.
#
# Variables modifiables :
#   ELK_MAJOR      branche Elastic (défaut : 9)
#   ELK_LOGSTASH   oui pour installer aussi Logstash avec une entrée Beats sur 5044 (défaut : non)

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

info "Suite Elastic (ELK) - Centralisation des journaux"

ELK_MAJOR="${ELK_MAJOR:-9}"
ELK_LOGSTASH="${ELK_LOGSTASH:-non}"

mem_mb=$(awk '/MemTotal/{print int($2/1024)}' /proc/meminfo)
[ "$mem_mb" -ge 3800 ] || warn "Mémoire : ${mem_mb} Mo. Elasticsearch + Kibana demandent 4 Go au minimum."

info "Dépôt Elastic ${ELK_MAJOR}.x"
pkg_update
pkg_install apt-transport-https gnupg curl ca-certificates
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor --yes -o /etc/apt/keyrings/elasticsearch.gpg
echo "deb [signed-by=/etc/apt/keyrings/elasticsearch.gpg] https://artifacts.elastic.co/packages/${ELK_MAJOR}.x/apt stable main" \
    > /etc/apt/sources.list.d/elastic-${ELK_MAJOR}.x.list
pkg_update

info "Installation d'Elasticsearch (configuration de sécurité automatique : TLS + mots de passe)"
pkg_install elasticsearch
systemctl daemon-reload
systemctl enable elasticsearch
systemctl restart elasticsearch
check_service_status elasticsearch

info "Mot de passe du compte elastic"
ELASTIC_PASS=$(/usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -b -s)
[ -n "$ELASTIC_PASS" ] || error_exit "Impossible de définir le mot de passe du compte elastic"

info "Installation de Kibana"
pkg_install kibana
KIBANA_YML=/etc/kibana/kibana.yml
backup_file "$KIBANA_YML"
if grep -qE '^#?server\.host:' "$KIBANA_YML"; then
    sed -i -E 's|^#?server\.host:.*|server.host: "0.0.0.0"|' "$KIBANA_YML"
else
    echo 'server.host: "0.0.0.0"' >> "$KIBANA_YML"
fi
if ! grep -q '^elasticsearch.hosts' "$KIBANA_YML"; then
    info "Inscription de Kibana auprès d'Elasticsearch (jeton d'inscription)"
    TOKEN=$(/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana)
    /usr/share/kibana/bin/kibana-setup --enrollment-token "$TOKEN"
fi
systemctl enable kibana
systemctl restart kibana
check_service_status kibana

ports=(9200/tcp 5601/tcp)
if [ "$ELK_LOGSTASH" = "oui" ]; then
    info "Installation de Logstash (entrée Beats sur le port 5044)"
    pkg_install logstash
    if [ ! -f /etc/logstash/conf.d/beats.conf ]; then
        cat > /etc/logstash/conf.d/beats.conf <<'EOF'
# Entrée Beats -> sortie à configurer (voir le README)
input {
  beats {
    port => 5044
  }
}
output {
  stdout { codec => rubydebug }
}
EOF
    fi
    systemctl enable logstash
    systemctl restart logstash
    ports+=(5044/tcp)
fi

open_ports "${ports[@]}"

save_credentials /root/elk_identifiants.txt \
    "Compte Elasticsearch / Kibana : elastic" \
    "Mot de passe                  : ${ELASTIC_PASS}" \
    "Certificat d'autorité         : /etc/elasticsearch/certs/http_ca.crt"

IP="$(hostname -I | awk '{print $1}')"
echo
echo "✅ Elasticsearch et Kibana installés (sécurité activée)"
echo "Kibana        : http://${IP}:5601 (compte elastic, mot de passe dans /root/elk_identifiants.txt)"
echo "Elasticsearch : https://${IP}:9200"
echo "Test          : sudo curl --cacert /etc/elasticsearch/certs/http_ca.crt -u elastic https://localhost:9200"
