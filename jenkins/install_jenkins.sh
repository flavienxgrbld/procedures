#!/usr/bin/env bash
# Installation de Jenkins LTS (dépôt officiel) avec Java 21.
#
# Variables modifiables :
#   JENKINS_PORT  port HTTP (défaut : 8080)

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

info "Jenkins LTS - Intégration et déploiement continus"

JENKINS_PORT="${JENKINS_PORT:-8080}"

info "Java 21 (Jenkins LTS 2.555 et suivantes : Java 21 ou 25 obligatoire)"
pkg_update
install_java_min 21
java -version 2>&1 | head -n1

info "Dépôt Jenkins LTS"
case "$PKG_MANAGER" in
    apt)
        install -m 0755 -d /etc/apt/keyrings
        download_file https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key /etc/apt/keyrings/jenkins-keyring.asc
        echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
            > /etc/apt/sources.list.d/jenkins.list
        pkg_update
        ;;
    dnf|yum)
        download_file https://pkg.jenkins.io/redhat-stable/jenkins.repo /etc/yum.repos.d/jenkins.repo
        rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2026.key
        ;;
    *) error_exit "Dépôt Jenkins disponible pour apt et dnf/yum seulement" ;;
esac
pkg_install jenkins

if [ "$JENKINS_PORT" != "8080" ]; then
    mkdir -p /etc/systemd/system/jenkins.service.d
    printf '[Service]\nEnvironment="JENKINS_PORT=%s"\n' "$JENKINS_PORT" > /etc/systemd/system/jenkins.service.d/port.conf
    systemctl daemon-reload
fi
systemctl enable jenkins
systemctl restart jenkins

info "Attente du mot de passe initial (premier démarrage : jusqu'à 2 minutes)"
SECRET=/var/lib/jenkins/secrets/initialAdminPassword
for _ in $(seq 1 60); do [ -s "$SECRET" ] && break; sleep 2; done
check_service_status jenkins
open_ports "${JENKINS_PORT}/tcp"

echo
echo "✅ Jenkins installé : http://$(primary_ip):${JENKINS_PORT}"
if [ -s "$SECRET" ]; then
    echo "Mot de passe initial : $(cat "$SECRET")"
else
    echo "Mot de passe initial (fichier pas encore créé) : sudo cat ${SECRET}"
fi
