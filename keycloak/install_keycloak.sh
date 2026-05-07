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

info "Keycloak - Gestion d'authentification et d'identité"

KEYCLOAK_VERSION="23.0.1"
KEYCLOAK_HOME="/opt/keycloak"
KEYCLOAK_USER="keycloak"

echo "=== Installation de Keycloak ==="

# Installation Java
case "$PKG_MANAGER" in
    apt)
        pkg_install openjdk-17-jre-headless
        ;;
    dnf|yum)
        pkg_install java-17-openjdk-headless
        ;;
esac

# Création utilisateur
if ! id "$KEYCLOAK_USER" >/dev/null 2>&1; then
    useradd -r -s /bin/bash -m -d "$KEYCLOAK_HOME" -c "Keycloak Service" "$KEYCLOAK_USER"
fi

# Installation Keycloak
cd /opt
wget "https://github.com/keycloak/keycloak/releases/download/${KEYCLOAK_VERSION}/keycloak-${KEYCLOAK_VERSION}.tar.gz"
tar -xzf "keycloak-${KEYCLOAK_VERSION}.tar.gz"
rm "keycloak-${KEYCLOAK_VERSION}.tar.gz"
mv "keycloak-${KEYCLOAK_VERSION}" keycloak
chown -R "$KEYCLOAK_USER:$KEYCLOAK_USER" "$KEYCLOAK_HOME"

# Service systemd
cat > /etc/systemd/system/keycloak.service <<'EOF'
[Unit]
Description=Keycloak
After=network.target

[Service]
Type=simple
User=keycloak
WorkingDirectory=/opt/keycloak
ExecStart=/opt/keycloak/bin/kc.sh start --hostname-url=http://localhost:8080 --hostname=localhost
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable keycloak

if command -v ufw >/dev/null 2>&1; then
    ufw allow 8080/tcp
fi

echo
echo "✅ Keycloak en cours d'installation"
echo "Démarrage du service: systemctl start keycloak"
echo "URL: http://votre-serveur:8080"
