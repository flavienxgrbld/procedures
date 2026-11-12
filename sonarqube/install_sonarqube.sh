#!/usr/bin/env bash
# Installation de SonarQube Community Build (image officielle) avec PostgreSQL, Docker Compose.

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

info "SonarQube - Analyse de la qualité du code"

APP_DIR="/opt/sonarqube"
mem_mb=$(awk '/MemTotal/{print int($2/1024)}' /proc/meminfo)
[ "$mem_mb" -ge 3800 ] || warn "Mémoire : ${mem_mb} Mo (4 Go minimum pour SonarQube et PostgreSQL)"

info "Réglages du noyau exigés par Elasticsearch (intégré à SonarQube)"
cat > /etc/sysctl.d/99-sonarqube.conf <<'EOF'
vm.max_map_count=524288
fs.file-max=131072
EOF
sysctl -q --system

ensure_docker
mkdir -p "$APP_DIR"; chmod 700 "$APP_DIR"
[ -f "${APP_DIR}/.env" ] || (umask 077; printf 'DB_PASSWORD=%s\n' "$(random_password 24)" > "${APP_DIR}/.env")

cat > "${APP_DIR}/compose.yaml" <<'EOF'
services:
  sonarqube:
    image: sonarqube:community
    restart: unless-stopped
    depends_on: [db]
    ports:
      - "9000:9000"
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://db:5432/sonar
      SONAR_JDBC_USERNAME: sonar
      SONAR_JDBC_PASSWORD: ${DB_PASSWORD}
    volumes:
      - sonar_data:/opt/sonarqube/data
      - sonar_extensions:/opt/sonarqube/extensions
      - sonar_logs:/opt/sonarqube/logs
    ulimits:
      nofile:
        soft: 131072
        hard: 131072

  db:
    image: postgres:17
    restart: unless-stopped
    environment:
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: sonar
    volumes:
      - pg_data:/var/lib/postgresql/data

volumes:
  sonar_data:
  sonar_extensions:
  sonar_logs:
  pg_data:
EOF
compose_up "$APP_DIR"
open_ports 9000/tcp

echo
echo "✅ SonarQube démarré : http://$(primary_ip):9000 (démarrage : 1 à 3 minutes)"
echo "Connexion : admin / admin -> changement de mot de passe imposé"
