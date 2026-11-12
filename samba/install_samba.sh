#!/usr/bin/env bash
# Serveur de fichiers Samba : partage réservé à un groupe, comptes Samba créés
# avec des mots de passe aléatoires (aucun accès invité).
#
# Variables modifiables :
#   SMB_SHARE  nom du partage (défaut : partage)
#   SMB_GROUP  groupe autorisé (défaut : nom du partage)
#   SMB_USERS  comptes à créer, séparés par des espaces (défaut : aucun ; ex. "alice bob")
#   SMB_PATH   dossier partagé (défaut : /srv/samba/<partage>)
#   SMB_WORKGROUP  groupe de travail (défaut : WORKGROUP)

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

info "Samba - Partage de fichiers SMB"

SMB_SHARE="${SMB_SHARE:-partage}"
SMB_GROUP="${SMB_GROUP:-$SMB_SHARE}"
SMB_PATH="${SMB_PATH:-/srv/samba/${SMB_SHARE}}"
SMB_WORKGROUP="${SMB_WORKGROUP:-WORKGROUP}"
CONF=/etc/samba/smb.conf

pkg_update
case "$PKG_MANAGER" in
    apt) pkg_install samba smbclient python3 ;;
    dnf|yum) pkg_install samba samba-client python3 ;;
    *) pkg_install samba ;;
esac

getent group "$SMB_GROUP" >/dev/null || groupadd "$SMB_GROUP"
mkdir -p "$SMB_PATH"
chown root:"$SMB_GROUP" "$SMB_PATH"
chmod 2770 "$SMB_PATH"

CREDS=()
for u in ${SMB_USERS:-}; do
    if ! id "$u" >/dev/null 2>&1; then
        useradd -M -s /usr/sbin/nologin "$u"
    fi
    usermod -aG "$SMB_GROUP" "$u"
    if ! pdbedit -L 2>/dev/null | grep -q "^${u}:"; then
        p="$(random_password 16)"
        printf '%s\n%s\n' "$p" "$p" | smbpasswd -s -a "$u" >/dev/null
        CREDS+=("${u} : ${p}")
    fi
done

[ -f "${CONF}.orig" ] || cp "$CONF" "${CONF}.orig"
backup_file "$CONF"
python3 - "$CONF" "$SMB_WORKGROUP" "$SMB_SHARE" "$SMB_PATH" "$SMB_GROUP" <<'PY'
import re, sys
path, wg, share, spath, group = sys.argv[1:6]
s = open(path).read()
def set_global(s, key, val):
    g = re.search(r'^\[global\]\s*$', s, re.M)
    if not g:
        return "[global]\n   %s = %s\n" % (key, val) + s
    end = re.search(r'^\[', s[g.end():], re.M)
    stop = g.end() + (end.start() if end else len(s) - g.end())
    block = s[g.end():stop]
    pat = re.compile(r'^\s*[#;]?\s*%s\s*=.*$' % re.escape(key), re.M)
    line = "   %s = %s" % (key, val)
    block = pat.sub(line, block, count=1) if pat.search(block) else "\n" + line + block
    return s[:g.end()] + block + s[stop:]
for k, v in [("workgroup", wg), ("security", "user"), ("map to guest", "never"), ("server min protocol", "SMB2")]:
    s = set_global(s, k, v)
s = re.sub(r'\n\[%s\]\n(?:(?!\n\[).)*' % re.escape(share), '\n', s, flags=re.S)
s = s.rstrip() + f"""

[{share}]
   path = {spath}
   valid users = @{group}
   read only = no
   browseable = yes
   create mask = 0660
   directory mask = 2770
   force group = {group}
"""
open(path, "w").write(s)
PY

testparm -s >/dev/null
SVC=smbd; systemctl list-unit-files smb.service >/dev/null 2>&1 && systemctl list-unit-files smb.service | grep -q '^smb.service' && SVC=smb
systemctl enable "$SVC"
systemctl restart "$SVC"
check_service_status "$SVC"
LAN="$(ip -4 route show scope link 2>/dev/null | awk '!/docker|br-|veth/ {print $1; exit}')" || true
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active" && [ -n "$LAN" ]; then
    ufw allow from "$LAN" to any port 445 proto tcp >/dev/null
elif command -v firewall-cmd >/dev/null 2>&1 && firewall-cmd --state >/dev/null 2>&1; then
    firewall-cmd --permanent --add-service=samba >/dev/null && firewall-cmd --reload >/dev/null
fi

[ ${#CREDS[@]} -gt 0 ] && save_credentials /root/samba_identifiants.txt "Partage \\\\$(primary_ip)\\${SMB_SHARE}" "${CREDS[@]}"
echo
echo "✅ Partage \\\\$(primary_ip)\\${SMB_SHARE} réservé au groupe ${SMB_GROUP}"
echo "Ajouter un compte : sudo useradd -M -s /usr/sbin/nologin -G ${SMB_GROUP} bob && sudo smbpasswd -a bob"
[ ${#CREDS[@]} -gt 0 ] && echo "Mots de passe Samba créés : /root/samba_identifiants.txt"
exit 0
