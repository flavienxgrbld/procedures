# Hurl — procédure d'installation

## Description

Hurl est un outil en ligne de commande, développé par Orange, qui exécute des requêtes HTTP décrites dans de simples fichiers texte et vérifie les réponses (codes, en-têtes, contenu JSON ou HTML). Il sert à tester des API REST et des sites web, en local comme en intégration continue.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu (paquet `.deb`) ; autres systèmes via archive |
| **Méthode** | Paquet officiel publié sur GitHub |
| **Ports** | Aucun (outil client) |
| **Script** | `install_hurl.sh` |

## Prérequis

- Un accès root pour l'installation et une connexion Internet.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/hurl
sudo bash install_hurl.sh
```

Lire les points d'attention : le script ne parvient plus à télécharger Hurl.

## Installation manuelle

### 1. Télécharger et installer le paquet

Prendre la dernière version sur la page des versions (ici la 8.0.1) :

```bash
cd /tmp
wget https://github.com/Orange-OpenSource/hurl/releases/download/8.0.1/hurl_8.0.1_amd64.deb
sudo apt install -y ./hurl_8.0.1_amd64.deb
hurl --version
```

### 2. Écrire un premier test

`test.hurl` :

```hurl
# La page d'accueil répond
GET https://example.org
HTTP 200
[Asserts]
header "Content-Type" contains "text/html"
xpath "string(//title)" == "Example Domain"

# Une API renvoie du JSON
GET https://api.github.com/repos/Orange-OpenSource/hurl
HTTP 200
[Asserts]
jsonpath "$.name" == "hurl"
```

### 3. Exécuter

```bash
hurl --test test.hurl
```

`--test` affiche un résumé (réussi ou échoué par fichier) et renvoie un code d'erreur en cas d'échec, ce qui convient à l'intégration continue.

## Vérification

```bash
hurl --version
hurl --test test.hurl
```

## Commandes utiles

| Commande | Rôle |
|---|---|
| `hurl fichier.hurl` | Exécuter et afficher la dernière réponse |
| `hurl --test *.hurl` | Lancer une série de tests |
| `hurl --variable host=http://localhost:8080 api.hurl` | Injecter une variable (`{{host}}` dans le fichier) |
| `hurl --test --report-html rapport/ *.hurl` | Générer un rapport HTML |

## Points d'attention

- Le script télécharge `https://raw.githubusercontent.com/Orange-OpenSource/hurl/master/install.sh`, qui n'existe pas (erreur 404, vérifié le 13/10/2026) : l'installation échoue. La variable `HURL_VERSION="4.1.0"` du script n'est pas utilisée.
- Hurl n'a besoin d'aucun droit root pour s'exécuter : seule l'installation du paquet en demande.

## Sources

- [Installation de Hurl](https://hurl.dev/docs/installation.html)
- [Documentation et exemples](https://hurl.dev/docs/samples.html)
