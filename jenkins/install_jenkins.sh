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

info "Jenkins - Automation serveur pour CI/CD"

JENKINS_HOME="/var/lib/jenkins"
JENKINS_USER="jenkins"

echo "=== Installation de Jenkins ==="
pkg_install curl

# Installation Java
case "$PKG_MANAGER" in
    apt)
        pkg_install default-jre default-jdk
        ;;
    dnf|yum)
        pkg_install java-11-openjdk java-11-openjdk-devel
        ;;
esac

# Dépôt Jenkins
case "$PKG_MANAGER" in
    apt)
        wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | apt-key add -
        sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
        pkg_update
        ;;
    dnf|yum)
        wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
        rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
        ;;
esac

pkg_install jenkins

systemctl daemon-reload
systemctl enable jenkins
systemctl start jenkins

if command -v ufw >/dev/null 2>&1; then
    ufw allow 8080/tcp
fi

sleep 10
JENKINS_PASS=$(cat $JENKINS_HOME/secrets/initialAdminPassword)

echo
echo "✅ Jenkins installé avec succès"
echo "URL: http://votre-serveur:8080"
echo "Mot de passe initial: $JENKINS_PASS"
