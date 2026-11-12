#!/usr/bin/env bash
# Installation de Rust (rustup) et de Rustlings pour l'utilisateur qui fera les exercices.
#
# Variables modifiables :
#   RUST_USER  utilisateur (défaut : celui qui a lancé sudo)

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

info "Rustlings - Exercices pour apprendre Rust"

RUST_USER="${RUST_USER:-${SUDO_USER:-}}"
[ -n "$RUST_USER" ] && [ "$RUST_USER" != "root" ] && id "$RUST_USER" >/dev/null 2>&1 \
    || error_exit "Lancer avec sudo depuis le compte qui fera les exercices, ou définir RUST_USER (pas root)"
USER_HOME="$(getent passwd "$RUST_USER" | cut -d: -f6)"

pkg_update
case "$PKG_MANAGER" in
    apt) pkg_install curl build-essential ;;
    dnf|yum) pkg_install curl gcc make ;;
    zypper) pkg_install curl gcc make ;;
    pacman) pkg_install curl base-devel ;;
esac

as_user() { sudo -u "$RUST_USER" -H bash -lc "$1"; }
pkg_install sudo
info "rustup (installation pour ${RUST_USER})"
as_user '[ -x "$HOME/.cargo/bin/rustup" ] || curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile default'
as_user '. "$HOME/.cargo/env" && rustup update stable && rustc --version'
info "Rustlings"
as_user '. "$HOME/.cargo/env" && cargo install rustlings --locked'
if [ ! -d "${USER_HOME}/rustlings" ]; then
    as_user 'cd "$HOME" && . "$HOME/.cargo/env" && rustlings init'
fi

echo
echo "✅ Rustlings installé pour ${RUST_USER}"
echo "Se reconnecter (ou « source ~/.cargo/env »), puis : cd ~/rustlings && rustlings"
