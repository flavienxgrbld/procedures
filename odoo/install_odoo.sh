#!/usr/bin/env bash
# Installation d'Odoo 19 Community (dépôt officiel) avec PostgreSQL et wkhtmltopdf,
# gestionnaire de bases protégé par un mot de passe maître.
#
# Variables modifiables :
#   ODOO_VERSION      branche (défaut : 19.0)
#   ODOO_MASTER_PASS  mot de passe maître (défaut : généré)

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

info "Odoo Community - Suite de gestion d'entreprise"

ODOO_VERSION="${ODOO_VERSION:-19.0}"
ODOO_MASTER_PASS="${ODOO_MASTER_PASS:-$(random_password 24)}"

pkg_update
pkg_install postgresql wget gpg ca-certificates
systemctl enable --now postgresql

install -m 0755 -d /etc/apt/keyrings
wget -qO- https://nightly.odoo.com/odoo.key | gpg --dearmor --yes -o /etc/apt/keyrings/odoo-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/odoo-archive-keyring.gpg] https://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/ ./" \
    > /etc/apt/sources.list.d/odoo.list
pkg_update
pkg_install odoo
pkg_install wkhtmltopdf || warn "wkhtmltopdf indisponible : l'impression des PDF ne fonctionnera pas (voir le README)"

CONF=/etc/odoo/odoo.conf
if grep -qE '^admin_passwd *= *(admin)?$' "$CONF" || ! grep -q '^admin_passwd' "$CONF"; then
    backup_file "$CONF"
    sed -i '/^admin_passwd/d' "$CONF"
    sed -i "/^\[options\]/a admin_passwd = ${ODOO_MASTER_PASS}" "$CONF"
    NEW_PASS=1
else
    NEW_PASS=0
fi
chown odoo:odoo "$CONF"
chmod 640 "$CONF"

systemctl enable odoo
systemctl restart odoo
check_service_status odoo
open_ports 8069/tcp
[ "$NEW_PASS" = 1 ] && save_credentials /root/odoo_identifiants.txt "Mot de passe maître (gestion des bases) : ${ODOO_MASTER_PASS}"

echo
echo "✅ Odoo ${ODOO_VERSION} installé : http://$(primary_ip):8069"
echo "Créer la base de l'entreprise avec le mot de passe maître (/root/odoo_identifiants.txt)."
