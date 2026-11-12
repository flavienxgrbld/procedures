#!/usr/bin/env bash
# Installation de GitLab Runner depuis le dépôt officiel, avec enregistrement
# facultatif (jeton glrt- créé dans l'interface GitLab).
#
# Variables facultatives :
#   RUNNER_URL       adresse de GitLab (défaut : https://gitlab.com)
#   RUNNER_TOKEN     jeton d'authentification glrt-... (sans lui : installation seule)
#   RUNNER_EXECUTOR  docker (défaut, Docker installé si besoin) ou shell
#   RUNNER_IMAGE     image par défaut de l'exécuteur docker (défaut : alpine:latest)

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

info "GitLab Runner - Exécution des pipelines CI/CD"

RUNNER_URL="${RUNNER_URL:-https://gitlab.com}"
RUNNER_EXECUTOR="${RUNNER_EXECUTOR:-docker}"
RUNNER_IMAGE="${RUNNER_IMAGE:-alpine:latest}"
case "$RUNNER_EXECUTOR" in docker|shell) ;; *) error_exit "RUNNER_EXECUTOR doit valoir docker ou shell" ;; esac

pkg_install curl ca-certificates
REPO_SH="$(mktemp)"
add_temp_file "$REPO_SH"
case "$PKG_MANAGER" in
    apt)     download_file https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh "$REPO_SH" ;;
    dnf|yum) download_file https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh "$REPO_SH" ;;
    *) error_exit "Dépôt GitLab Runner disponible pour apt, dnf et yum seulement" ;;
esac
info "Ajout du dépôt officiel GitLab Runner"
bash "$REPO_SH"
pkg_install gitlab-runner
gitlab-runner --version | head -n1

if [ "$RUNNER_EXECUTOR" = "docker" ]; then
    ensure_docker
    usermod -aG docker gitlab-runner
fi

systemctl enable --now gitlab-runner

if [ -n "${RUNNER_TOKEN:-}" ]; then
    case "$RUNNER_TOKEN" in glrt-*) ;; *) warn "Le jeton ne commence pas par glrt- : les jetons d'enregistrement anciens sont dépréciés par GitLab" ;; esac
    info "Enregistrement du runner auprès de ${RUNNER_URL} (exécuteur ${RUNNER_EXECUTOR})"
    opts=(--non-interactive --url "$RUNNER_URL" --token "$RUNNER_TOKEN" --executor "$RUNNER_EXECUTOR" --description "$(hostname -s)")
    [ "$RUNNER_EXECUTOR" = "docker" ] && opts+=(--docker-image "$RUNNER_IMAGE")
    gitlab-runner register "${opts[@]}"
    gitlab-runner verify
    systemctl restart gitlab-runner
fi

echo
echo "✅ GitLab Runner installé"
if [ -z "${RUNNER_TOKEN:-}" ]; then
    echo "Pour l'enregistrer (jeton créé dans GitLab : Paramètres > CI/CD > Runners) :"
    echo "  sudo RUNNER_TOKEN=glrt-xxxx bash install_gitlab_runner.sh"
fi
echo "État : sudo gitlab-runner list"
