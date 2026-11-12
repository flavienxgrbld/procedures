#!/usr/bin/env bash
# Installation de SeaweedFS (binaire officiel weed) sur un nœud : master, volume,
# filer et API S3 protégée par des identifiants.
#
# Variables modifiables :
#   WEED_VERSION  version (défaut : dernière publiée)
#   WEED_IP       adresse annoncée (défaut : adresse principale)

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

info "SeaweedFS - Stockage distribué compatible S3"
command -v systemctl >/dev/null 2>&1 || error_exit "systemd est requis"

WEED_VERSION="${WEED_VERSION:-$(github_latest_tag seaweedfs/seaweedfs 4.53)}"
WEED_IP="${WEED_IP:-$(primary_ip)}"
case "$(uname -m)" in x86_64) ARCH=amd64 ;; aarch64|arm64) ARCH=arm64 ;; *) error_exit "Architecture non gérée" ;; esac

pkg_install curl tar
WORK="$(mktemp -d)"; add_temp_file "$WORK"
download_file "https://github.com/seaweedfs/seaweedfs/releases/download/${WEED_VERSION}/linux_${ARCH}.tar.gz" "${WORK}/weed.tar.gz"
tar -xzf "${WORK}/weed.tar.gz" -C "$WORK"
install -m 0755 "${WORK}/weed" /usr/local/bin/weed
weed version

id seaweedfs >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin seaweedfs
mkdir -p /var/lib/seaweedfs /etc/seaweedfs
chown seaweedfs:seaweedfs /var/lib/seaweedfs

S3=/etc/seaweedfs/s3.json
if [ ! -f "$S3" ]; then
    S3_KEY="admin"; S3_SECRET="$(random_password 40)"
    cat > "$S3" <<EOF
{
  "identities": [
    {
      "name": "admin",
      "credentials": [{ "accessKey": "${S3_KEY}", "secretKey": "${S3_SECRET}" }],
      "actions": ["Admin", "Read", "Write", "List", "Tagging"]
    }
  ]
}
EOF
    save_credentials /root/seaweedfs_identifiants.txt "API S3 : http://${WEED_IP}:8333" "Access key : ${S3_KEY}" "Secret key : ${S3_SECRET}"
fi
chown root:seaweedfs "$S3"; chmod 640 "$S3"

cat > /etc/systemd/system/seaweedfs.service <<EOF
[Unit]
Description=SeaweedFS (master, volume, filer, S3)
After=network.target

[Service]
User=seaweedfs
Group=seaweedfs
ExecStart=/usr/local/bin/weed server -dir=/var/lib/seaweedfs -ip=${WEED_IP} -filer -s3 -s3.config=${S3}
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable seaweedfs
systemctl restart seaweedfs
sleep 3
check_service_status seaweedfs
LAN="$(ip -4 route show scope link 2>/dev/null | awk '!/docker|br-|veth/ {print $1; exit}')" || true
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active" && [ -n "$LAN" ]; then
    ufw allow from "$LAN" to any port 8333 proto tcp >/dev/null
fi

echo
echo "✅ SeaweedFS ${WEED_VERSION} démarré : API S3 http://${WEED_IP}:8333 (identifiants : /root/seaweedfs_identifiants.txt)"
