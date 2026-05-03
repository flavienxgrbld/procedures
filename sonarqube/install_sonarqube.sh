#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "SonarQube - Analyse de qualité du code"

SONARQUBE_VERSION="latest"
SONAR_USER="sonarqube"
SONAR_HOME="/opt/sonarqube"

echo "=== Mise à jour du système ==="
pkg_update
pkg_upgrade

# Installation Java JDK
echo "=== Installation de Java JDK ==="
case "$PKG_MANAGER" in
    apt)
        pkg_install openjdk-11-jdk
        ;;
    dnf|yum)
        pkg_install java-11-openjdk java-11-openjdk-devel
        ;;
    zypper)
        pkg_install java-11-openjdk java-11-openjdk-devel
        ;;
    pacman)
        pkg_install jdk11-openjdk
        ;;
esac

echo "=== Installation PostgreSQL pour SonarQube ==="
. "$SCRIPT_DIR/../databases/install_postgresql.sh" || pkg_install postgresql postgresql-client

# Création utilisateur SonarQube
if ! id "$SONAR_USER" >/dev/null 2>&1; then
    useradd -r -s /bin/bash -m -d "$SONAR_HOME" -c "SonarQube Service" "$SONAR_USER"
fi

# Installation SonarQube
echo "=== Installation de SonarQube ==="
cd /opt

if [ "$SONARQUBE_VERSION" = "latest" ]; then
    SONARQUBE_URL="https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-latest.zip"
else
    SONARQUBE_URL="https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONARQUBE_VERSION}.zip"
fi

wget "$SONARQUBE_URL" -O sonarqube.zip
unzip sonarqube.zip
rm sonarqube.zip
mv sonarqube-* sonarqube

chown -R "$SONAR_USER:$SONAR_USER" "$SONAR_HOME"

# Configuration
cat > "$SONAR_HOME/conf/sonar.properties" <<'EOF'
sonar.web.host=0.0.0.0
sonar.web.port=9000
sonar.web.context=/
sonar.jdbc.url=jdbc:postgresql://localhost:5432/sonarqube
sonar.jdbc.username=sonarqube
sonar.jdbc.password=sonarqube
EOF

# Service systemd
cat > /etc/systemd/system/sonarqube.service <<EOF
[Unit]
Description=SonarQube
After=network.target

[Service]
Type=simple
User=$SONAR_USER
Group=$SONAR_USER
ExecStart=$SONAR_HOME/bin/linux-x86-64/sonar.sh console
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable sonarqube
systemctl start sonarqube

if command -v ufw >/dev/null 2>&1; then
    ufw allow 9000/tcp
fi

echo
echo "✅ SonarQube en cours d'installation"
echo "URL: http://votre-serveur:9000"
echo "Login/Mot de passe par défaut: admin/admin"
