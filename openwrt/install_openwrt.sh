#!/usr/bin/env bash
# OpenWrt est un système complet : il ne s'installe pas « sur » un serveur.
# Lancé sur un hôte Proxmox VE, ce script crée une VM OpenWrt x86-64 prête à démarrer.
# Ailleurs, il affiche la méthode pour un routeur compatible.
#
# Variables (Proxmox) :
#   OPENWRT_VERSION  version (défaut : 25.12.6)
#   OPENWRT_VMID     numéro de VM (défaut : premier libre)
#   OPENWRT_LAN_BR   pont du LAN (défaut : vmbr1)   OPENWRT_WAN_BR  pont du WAN (défaut : vmbr0)
#   OPENWRT_STORAGE  stockage des disques (défaut : local-lvm)

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

info "OpenWrt - Système pour routeurs"

OPENWRT_VERSION="${OPENWRT_VERSION:-25.12.6}"

if ! command -v qm >/dev/null 2>&1; then
    cat <<EOF
Ce serveur n'est pas un hôte Proxmox : rien n'est installé ici.

Routeur compatible :
  1. Vérifier le modèle ET la révision matérielle dans la Table of Hardware : https://openwrt.org/toh/start
  2. Télécharger l'image « factory » (première installation) ou « sysupgrade » (mise à jour)
     avec le Firmware Selector : https://firmware-selector.openwrt.org/
  3. La flasher depuis l'interface du constructeur, puis se connecter à http://192.168.1.1 (LuCI).

Machine virtuelle : relancer ce script sur un hôte Proxmox VE (méthode 2 du README).
EOF
    exit 0
fi

OPENWRT_VMID="${OPENWRT_VMID:-$(pvesh get /cluster/nextid)}"
OPENWRT_LAN_BR="${OPENWRT_LAN_BR:-vmbr1}"
OPENWRT_WAN_BR="${OPENWRT_WAN_BR:-vmbr0}"
OPENWRT_STORAGE="${OPENWRT_STORAGE:-local-lvm}"
for br in "$OPENWRT_LAN_BR" "$OPENWRT_WAN_BR"; do
    ip link show "$br" >/dev/null 2>&1 || error_exit "Pont réseau ${br} introuvable (définir OPENWRT_LAN_BR / OPENWRT_WAN_BR)"
done
qm status "$OPENWRT_VMID" >/dev/null 2>&1 && error_exit "La VM ${OPENWRT_VMID} existe déjà"

IMG="openwrt-${OPENWRT_VERSION}-x86-64-generic-ext4-combined-efi.img"
WORK="$(mktemp -d)"
add_temp_file "$WORK"
info "Téléchargement de ${IMG}.gz"
download_file "https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/x86/64/${IMG}.gz" "${WORK}/${IMG}.gz"
download_file "https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/x86/64/sha256sums" "${WORK}/sha256sums"
(cd "$WORK" && grep -E " \*?${IMG}.gz\$" sha256sums | sha256sum -c -) || error_exit "Somme de contrôle invalide"
# gunzip renvoie 2 (« trailing garbage ») sur les images OpenWrt : c'est normal
gunzip -f "${WORK}/${IMG}.gz" || [ -f "${WORK}/${IMG}" ]

info "Création de la VM ${OPENWRT_VMID} (LAN ${OPENWRT_LAN_BR} = net0, WAN ${OPENWRT_WAN_BR} = net1)"
qm create "$OPENWRT_VMID" --name openwrt --memory 512 --cores 1 --bios ovmf --machine q35 \
    --net0 "virtio,bridge=${OPENWRT_LAN_BR}" --net1 "virtio,bridge=${OPENWRT_WAN_BR}" --ostype l26 \
    --efidisk0 "${OPENWRT_STORAGE}:0,efitype=4m,pre-enrolled-keys=0" --serial0 socket --vga serial0
qm importdisk "$OPENWRT_VMID" "${WORK}/${IMG}" "$OPENWRT_STORAGE" >/dev/null
DISK="$(qm config "$OPENWRT_VMID" | awk -F': ' '/^unused0/{print $2}')"
qm set "$OPENWRT_VMID" --scsihw virtio-scsi-pci --scsi0 "$DISK" --boot order=scsi0 >/dev/null

echo
echo "✅ VM OpenWrt ${OPENWRT_VERSION} créée (n° ${OPENWRT_VMID})"
echo "Démarrer : qm start ${OPENWRT_VMID} ; console : qm terminal ${OPENWRT_VMID}"
echo "Puis, depuis le LAN (${OPENWRT_LAN_BR}) : http://192.168.1.1 et définir le mot de passe root."
