#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../install_common.sh"

ensure_root
detect_os
detect_package_manager

info "OpenWrt - Système d'exploitation WiFi/routeur"

echo "=== Installation d'OpenWrt ==="
echo "⚠️  Important: OpenWrt s'installe généralement sur du matériel spécifique"
echo "Pas d'installation standard sur serveur"
echo ""
echo "Pour installer OpenWrt:"
echo "1. Téléchargez l'image depuis https://openwrt.org/downloads"
echo "2. Flashez-la sur votre routeur/point d'accès"
echo "3. Accédez via http://192.168.1.1"
echo ""
echo "Matériel compatible:"
echo "- Routeurs TP-Link, D-Link, Netgear, etc."
echo "- Vérifiez la liste des appareils: https://openwrt.org/toh"
