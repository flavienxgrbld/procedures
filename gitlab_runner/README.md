# GitLab Runner — procédure d'installation

## Description

GitLab Runner est l'agent qui exécute les tâches d'intégration et de déploiement continus (CI/CD) définies dans le fichier `.gitlab-ci.yml` d'un projet GitLab. Cette procédure installe le runner depuis le dépôt officiel de GitLab et l'enregistre auprès d'une instance GitLab.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu, RHEL/Fedora |
| **Méthode** | Dépôt officiel `packages.gitlab.com` |
| **Ports** | Aucun port entrant (le runner contacte GitLab en HTTPS) |
| **Script** | `install_gitlab_runner.sh` |

## Prérequis

- Un accès root et une connexion Internet.
- Un accès **Maintainer** (ou plus) sur le projet ou le groupe GitLab, pour créer le runner.
- Docker installé si l'on choisit l'exécuteur `docker` (voir la procédure `docker`).

## Installation automatique

Créer d'abord le runner dans GitLab (étape 2) pour obtenir son jeton `glrt-`, puis :

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/gitlab_runner
sudo RUNNER_URL=https://gitlab.com RUNNER_TOKEN=glrt-XXXXXXXXXXXXXXXX bash install_gitlab_runner.sh
```

Le script ajoute le dépôt officiel, installe `gitlab-runner`, installe Docker si l'exécuteur est `docker` (par défaut) en ajoutant `gitlab-runner` au groupe `docker`, puis enregistre le runner sans question et vérifie la connexion. Sans `RUNNER_TOKEN`, il s'arrête après l'installation. Variables : `RUNNER_EXECUTOR` (`docker` ou `shell`), `RUNNER_IMAGE` (défaut `alpine:latest`).

## Installation manuelle

### 1. Ajouter le dépôt et installer

```bash
curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash
sudo apt install -y gitlab-runner
gitlab-runner --version
```

### 2. Créer le runner dans GitLab

Dans le projet : *Paramètres → CI/CD → Runners → Nouveau runner de projet*.

- Choisir **Linux**, ajouter des étiquettes (par exemple `docker`, `linux`) ou cocher « Exécuter les tâches sans étiquette ».
- Valider : GitLab affiche un **jeton d'authentification** commençant par `glrt-`.

### 3. Enregistrer le runner sur le serveur

```bash
sudo gitlab-runner register \
  --url https://gitlab.com \
  --token glrt-XXXXXXXXXXXXXXXX
```

Répondre aux questions :

| Question | Réponse |
|---|---|
| Executor | `docker` (isolation) ou `shell` (commandes directes sur l'hôte) |
| Default Docker image | `alpine:latest` (si exécuteur docker) |

Avec l'exécuteur `docker`, ajouter l'utilisateur du runner au groupe `docker` :

```bash
sudo usermod -aG docker gitlab-runner
```

### 4. Démarrer le service

```bash
sudo systemctl enable --now gitlab-runner
```

### 5. Tester avec un pipeline

Dans le dépôt, créer `.gitlab-ci.yml` :

```yaml
test:
  script:
    - echo "Le runner fonctionne"
    - uname -a
```

## Vérification

```bash
sudo gitlab-runner verify
sudo gitlab-runner list
systemctl status gitlab-runner
```

Dans GitLab, le runner apparaît en vert dans la page *Runners*, et le pipeline de test réussit.

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/gitlab-runner/config.toml` | Configuration des runners enregistrés (jetons, exécuteurs) |

## Dépannage

- Tâche en attente indéfiniment : vérifier les étiquettes (le job doit les demander, ou le runner doit accepter les jobs sans étiquette).
- Journal : `journalctl -u gitlab-runner -f`.

## Points d'attention

- L'exécuteur `shell` lance les jobs directement sur le serveur, avec les droits de l'utilisateur `gitlab-runner` : le réserver à des projets de confiance. Avec l'exécuteur `docker`, l'appartenance au groupe `docker` donne aussi des droits élevés sur l'hôte : un runner ne doit pas tourner sur un serveur qui héberge autre chose de sensible.
- Les jetons d'enregistrement (`registration token`) sont dépréciés par GitLab : utiliser le jeton `glrt-` créé dans l'interface.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Installer GitLab Runner (dépôt Linux)](https://docs.gitlab.com/runner/install/linux-repository/)
- [Enregistrer un runner](https://docs.gitlab.com/runner/register/)
