# LuaJIT — procédure d'installation

## Description

LuaJIT est un compilateur à la volée (*Just-In-Time*) pour le langage Lua, beaucoup plus rapide que l'interpréteur standard. Il est utilisé par OpenResty (Nginx scriptable), par certains jeux, et pour écrire des scripts ou des extensions performants. Cette procédure l'installe depuis les dépôts, ou le compile depuis les sources officielles.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu (paquet `luajit`) ; toute distribution par compilation |
| **Méthode** | Paquet de la distribution, ou compilation depuis le dépôt officiel |
| **Ports** | Aucun (outil local) |
| **Script** | `install_luajit.sh` |

## Prérequis

- Un accès root pour l'installation.
- Pour compiler : `gcc`, `make` et `git`.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/luajit
sudo bash install_luajit.sh
```

Le script compile LuaJIT depuis les sources et l'installe dans `/usr/local`.

## Installation manuelle

### Méthode 1 : paquet de la distribution (le plus simple)

```bash
sudo apt update
sudo apt install -y luajit libluajit-5.1-dev
luajit -v
```

### Méthode 2 : compilation depuis les sources (dernière version)

```bash
sudo apt update
sudo apt install -y build-essential git
cd /tmp
git clone https://luajit.org/git/luajit.git
cd luajit
make -j"$(nproc)"
sudo make install
sudo ldconfig
luajit -v
```

LuaJIT est installé dans `/usr/local/bin/luajit`, et ses en-têtes dans `/usr/local/include/luajit-2.1`.

## Premier essai

`bonjour.lua` :

```lua
local debut = os.clock()
local somme = 0
for i = 1, 1e8 do somme = somme + i end
print("Somme :", somme, string.format("en %.2f s", os.clock() - debut))
```

```bash
luajit bonjour.lua
```

## Vérification

```bash
luajit -v
luajit -e 'print(jit.version, jit.status())'
```

## Dépannage

- **`luajit: command not found` après compilation** : `/usr/local/bin` n'est pas dans le `PATH`, ou il faut relancer le terminal.
- **Erreur de bibliothèque partagée** : lancer `sudo ldconfig`.

## Points d'attention

- Le script n'installe pas `git`, qu'il utilise pour récupérer les sources : sur une machine minimale, il s'arrête au clonage.
- Il installe `libreadline-dev`, inutile pour LuaJIT.
- LuaJIT est compatible avec Lua 5.1 (et quelques ajouts de 5.2), pas avec les versions plus récentes du langage.

## Sources

- [Installation de LuaJIT](https://luajit.org/install.html)
- [Site officiel LuaJIT](https://luajit.org/)
