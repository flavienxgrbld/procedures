# Rustlings — procédure d'installation

## Description

Rustlings est un ensemble de petits exercices pour apprendre le langage Rust : chaque exercice contient une erreur à corriger ou un code à compléter, et l'outil vérifie automatiquement les réponses. Cette procédure installe Rust avec rustup, puis Rustlings, pour un utilisateur.

| | |
|---|---|
| **Systèmes** | Linux, macOS, Windows |
| **Méthode** | rustup (installateur officiel de Rust) + `cargo install rustlings` |
| **Ports** | Aucun |
| **Script** | `install_rustlings.sh` |

## Prérequis

- Un compte utilisateur normal (pas root) : Rust et Rustlings s'installent dans le dossier personnel.
- `curl` et un compilateur C (`build-essential`).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/rustlings
sudo bash install_rustlings.sh
```

Lire les points d'attention : le script d'installation qu'il télécharge n'existe plus.

## Installation manuelle

### 1. Installer les outils de compilation

```bash
sudo apt update
sudo apt install -y curl build-essential
```

### 2. Installer Rust avec rustup (sans sudo)

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
rustc --version
```

Choisir l'installation par défaut (`1`).

### 3. Installer Rustlings

```bash
cargo install rustlings --locked
```

### 4. Créer le dossier d'exercices

```bash
cd ~
rustlings init
cd rustlings
rustlings
```

`rustlings` lance le mode interactif : il affiche l'exercice en cours et revérifie à chaque enregistrement du fichier. Ouvrir le dossier `rustlings` dans un éditeur (VS Code avec l'extension *rust-analyzer* par exemple).

## Vérification

```bash
rustlings --version
```

Dans le mode interactif, la barre de progression indique le nombre d'exercices réussis.

## Commandes utiles (dans le mode interactif)

| Touche | Action |
|---|---|
| `h` | Afficher un indice |
| `n` | Passer à l'exercice suivant (une fois réussi) |
| `l` | Liste des exercices |
| `q` | Quitter |

## Points d'attention

- Le script télécharge `https://raw.githubusercontent.com/rust-lang/rustlings/main/install.sh`, qui n'existe plus (erreur 404, vérifié le 13/10/2026) : Rustlings 6 s'installe avec `cargo install rustlings`.
- Il installe le paquet `rustc` de la distribution, souvent trop ancien pour les exercices, au lieu de rustup.
- Lancé avec `sudo`, il installe tout pour root : Rustlings doit être installé par l'utilisateur qui fait les exercices.

## Sources

- [Installation de Rustlings](https://rustlings.rust-lang.org/setup/)
- [Installer Rust](https://www.rust-lang.org/tools/install)
