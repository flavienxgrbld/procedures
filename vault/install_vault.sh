#!/usr/bin/env bash
# Installation de HashiCorp Vault (dépôt officiel) : stockage intégré Raft, TLS,
# initialisation et descellement.
#
# Variables modifiables :
#   VAULT_ADDR_IP  adresse annoncée (défaut : adresse principale)
#   VAULT_SHARES / VAULT_THRESHOLD  parts de la clé de descellement (défaut : 5 / 3)

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

info "Vault - Gestion des secrets"

VAULT_ADDR_IP="${VAULT_ADDR_IP:-$(primary_ip)}"
VAULT_SHARES="${VAULT_SHARES:-5}"
VAULT_THRESHOLD="${VAULT_THRESHOLD:-3}"
INIT_FILE=/root/vault_init.json

hashicorp_repo
pkg_install vault jq
mkdir -p /opt/vault/data
chown -R vault:vault /opt/vault/data

TLS_DIR=/opt/vault/tls
if [ ! -s "${TLS_DIR}/tls.crt" ] || ! openssl x509 -in "${TLS_DIR}/tls.crt" -noout -text | grep -q "IP Address:${VAULT_ADDR_IP}"; then
    info "Certificat autosigné pour ${VAULT_ADDR_IP}"
    mkdir -p "$TLS_DIR"
    openssl req -x509 -newkey rsa:4096 -sha256 -days 825 -nodes \
        -keyout "${TLS_DIR}/tls.key" -out "${TLS_DIR}/tls.crt" -subj "/CN=$(hostname -f)" \
        -addext "subjectAltName=DNS:$(hostname -f),DNS:localhost,IP:${VAULT_ADDR_IP},IP:127.0.0.1" 2>/dev/null
    chown vault:vault "${TLS_DIR}"/tls.*; chmod 600 "${TLS_DIR}/tls.key"
fi

backup_file /etc/vault.d/vault.hcl
cat > /etc/vault.d/vault.hcl <<EOF
ui = true

storage "raft" {
  path    = "/opt/vault/data"
  node_id = "$(hostname -s)"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "${TLS_DIR}/tls.crt"
  tls_key_file  = "${TLS_DIR}/tls.key"
}

api_addr     = "https://${VAULT_ADDR_IP}:8200"
cluster_addr = "https://${VAULT_ADDR_IP}:8201"
EOF
chown vault:vault /etc/vault.d/vault.hcl; chmod 640 /etc/vault.d/vault.hcl

systemctl enable vault
systemctl restart vault
sleep 3
check_service_status vault

export VAULT_ADDR="https://127.0.0.1:8200" VAULT_CACERT="${TLS_DIR}/tls.crt"
# vault status : 0 = descellé, 2 = scellé, 1 = injoignable
for _ in $(seq 1 20); do rc=0; vault status >/dev/null 2>&1 || rc=$?; [ "$rc" -ne 1 ] && break; sleep 1; done

if [ "$(vault status -format=json 2>/dev/null | jq -r .initialized)" != "true" ]; then
    info "Initialisation (${VAULT_SHARES} parts, ${VAULT_THRESHOLD} nécessaires)"
    (umask 077; vault operator init -key-shares="$VAULT_SHARES" -key-threshold="$VAULT_THRESHOLD" -format=json > "$INIT_FILE")
    for i in $(seq 0 $((VAULT_THRESHOLD - 1))); do
        vault operator unseal "$(jq -r ".unseal_keys_b64[$i]" "$INIT_FILE")" >/dev/null
    done
    INIT_DONE=1
else
    INIT_DONE=0
    [ "$(vault status -format=json | jq -r .sealed)" = "true" ] && warn "Vault est scellé : le desceller avec « vault operator unseal » (${VAULT_THRESHOLD} clés)"
fi

LAN="$(ip -4 route show scope link 2>/dev/null | awk '!/docker|br-|veth/ {print $1; exit}')" || true
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active" && [ -n "$LAN" ]; then
    ufw allow from "$LAN" to any port 8200 proto tcp >/dev/null
fi

echo
echo "✅ Vault installé : https://${VAULT_ADDR_IP}:8200/ui"
if [ "$INIT_DONE" = 1 ]; then
    echo "⚠️  Clés de descellement et jeton root : ${INIT_FILE}"
    echo "    Les distribuer à des personnes différentes, puis SUPPRIMER ce fichier du serveur."
fi
echo "Après chaque redémarrage, Vault est scellé : vault operator unseal (${VAULT_THRESHOLD} fois)."
