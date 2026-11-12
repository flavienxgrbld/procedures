#!/usr/bin/env bash
# Installation de Proxmox VE 9 sur un Debian 13 « Trixie » existant (méthode officielle
# « Install Proxmox VE on Debian 13 Trixie »), en deux passes séparées par un redémarrage :
#   1re exécution : dépôt Proxmox (sans abonnement) + noyau Proxmox, puis redémarrage
#   2e exécution  : paquets proxmox-ve, retrait du noyau Debian
# Pour une machine neuve, l'ISO officielle reste la méthode la plus simple (voir le README).
#
# Variables :
#   PROXMOX_CONFIRM=oui  obligatoire (la machine devient un hyperviseur dédié)

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

info "Proxmox VE 9 sur Debian 13"

[ "$OS_ID" = "debian" ] && [ "${OS_VERSION_ID%%.*}" = "13" ] || error_exit "Proxmox VE 9 s'installe sur Debian 13 « Trixie » (détecté : ${OS_NAME} ${OS_VERSION_ID}) ; sinon utiliser l'ISO"
[ "$(uname -m)" = "x86_64" ] || error_exit "Proxmox VE demande un processeur 64 bits x86"
[ "${PROXMOX_CONFIRM:-}" = "oui" ] || error_exit "La machine va devenir un hyperviseur dédié : relancer avec PROXMOX_CONFIRM=oui"
grep -qE 'vmx|svm' /proc/cpuinfo || warn "Virtualisation matérielle (VT-x/AMD-V) non détectée : les VM KVM ne démarreront pas"

# Le nom de la machine doit résoudre vers son adresse IP réelle (pas 127.0.1.1)
FQDN="$(hostname -f 2>/dev/null || hostname)"
IP="$(primary_ip)"
RESOLVED="$(getent hosts "$(hostname)" | awk '{print $1; exit}')" || true
if [ "$RESOLVED" != "$IP" ]; then
    info "/etc/hosts : $(hostname) -> ${IP}"
    backup_file /etc/hosts
    sed -i "/[[:space:]]$(hostname)\([[:space:]]\|\$\)/d" /etc/hosts
    echo "${IP} ${FQDN} $(hostname -s)" >> /etc/hosts
fi

if ! dpkg -s proxmox-default-kernel >/dev/null 2>&1; then
    info "Passe 1 : dépôt pve-no-subscription et noyau Proxmox"
    pkg_install wget ca-certificates
    KEY=/usr/share/keyrings/proxmox-archive-keyring.gpg
    download_file https://enterprise.proxmox.com/debian/proxmox-archive-keyring-trixie.gpg "$KEY"
    echo "136673be77aba35dcce385b28737689ad64fd785a797e57897589aed08db6e45  ${KEY}" | sha256sum -c - \
        || error_exit "Somme de contrôle de la clé Proxmox invalide"
    cat > /etc/apt/sources.list.d/pve-install-repo.sources <<EOF
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: ${KEY}
EOF
    pkg_update
    DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y
    pkg_install proxmox-default-kernel
    echo
    echo "✅ Passe 1 terminée. Redémarrer sur le noyau Proxmox, puis relancer :"
    echo "   sudo reboot"
    echo "   sudo PROXMOX_CONFIRM=oui bash install_proxmox.sh"
    exit 0
fi

uname -r | grep -q pve || error_exit "Le noyau Proxmox n'est pas encore démarré (uname -r : $(uname -r)) : redémarrer d'abord"

info "Passe 2 : paquets Proxmox VE"
echo "postfix postfix/main_mailer_type select Local only" | debconf-set-selections
echo "postfix postfix/mailname string ${FQDN}" | debconf-set-selections
pkg_install proxmox-ve postfix open-iscsi chrony

info "Retrait du noyau Debian et d'os-prober"
mapfile -t DEB_KERNELS < <(dpkg -l | awk '/^ii +linux-image-[0-9].*-amd64/ {print $2}')
if [ ${#DEB_KERNELS[@]} -gt 0 ]; then
    DEBIAN_FRONTEND=noninteractive apt-get remove -y linux-image-amd64 "${DEB_KERNELS[@]}"
fi
DEBIAN_FRONTEND=noninteractive apt-get remove -y os-prober 2>/dev/null || true
update-grub

open_ports 8006/tcp

echo
echo "✅ Proxmox VE installé : https://${IP}:8006 (compte root, domaine « Linux PAM »)"
echo "Créer ensuite le pont réseau vmbr0 : Nœud > Système > Réseau (voir le README)."
