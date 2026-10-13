# Hyperledger Fabric — procédure d'installation

## Description

Hyperledger Fabric est une plateforme de blockchain privée (permissionnée) pour les entreprises : seuls les membres identifiés participent au réseau, et la logique métier s'écrit dans des contrats intelligents (*chaincode*). Cette procédure installe les prérequis, les binaires, les images Docker et le réseau d'exemple `test-network` pour découvrir Fabric.

| | |
|---|---|
| **Systèmes** | Ubuntu, Debian (64 bits) |
| **Méthode** | Script officiel `install-fabric.sh` |
| **Dossier** | `/opt/fabric` |
| **Ports** | 7050 (orderer), 7051 et 9051 (peers) dans le réseau de test |
| **Script** | `install_hyperledger_fabric.sh` |

## Prérequis

- Docker et Docker Compose (voir la procédure `docker`), Git et curl.
- 4 Go de RAM au minimum.
- Pour écrire du chaincode : Go ou Node.js.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/hyperledger_fabric
sudo bash install_hyperledger_fabric.sh
```

Le script installe Docker, Docker Compose, Git et curl, puis télécharge dans `/opt/fabric` les binaires, les images Docker et les exemples.

## Installation manuelle

### 1. Installer les prérequis

```bash
sudo apt update
sudo apt install -y git curl jq
```

Installer Docker en suivant la procédure `docker`, puis ajouter son utilisateur au groupe `docker`.

### 2. Télécharger Fabric

```bash
mkdir -p ~/fabric && cd ~/fabric
curl -sSLO https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh
chmod +x install-fabric.sh
./install-fabric.sh docker binary samples
```

Le script crée le dossier `fabric-samples`, avec les binaires dans `fabric-samples/bin` (`peer`, `orderer`, `configtxgen`…), et télécharge les images Docker.

### 3. Ajouter les binaires au PATH

```bash
echo 'export PATH=$HOME/fabric/fabric-samples/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
peer version
```

### 4. Démarrer le réseau de test

```bash
cd ~/fabric/fabric-samples/test-network
./network.sh up createChannel -c canal1
```

Le réseau démarre deux organisations avec un peer chacune et un orderer, puis crée le canal `canal1`.

### 5. Déployer un chaincode d'exemple

```bash
./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go -ccl go -c canal1
```

### 6. Arrêter le réseau

```bash
./network.sh down
```

## Vérification

```bash
docker ps --format '{{.Names}}'
```

Les conteneurs `orderer.example.com`, `peer0.org1.example.com` et `peer0.org2.example.com` doivent être actifs.

## Dépannage

- **Permission denied sur Docker** : l'utilisateur n'est pas dans le groupe `docker`, ou ne s'est pas reconnecté.
- Repartir de zéro : `./network.sh down`, puis `docker volume prune`.

## Points d'attention

- Le script travaille dans `/opt/fabric` en root : les fichiers générés appartiennent à root et le réseau de test doit alors être lancé avec `sudo`. Installer plutôt dans le dossier personnel d'un utilisateur du groupe `docker`.
- Le message final du script propose `./bin/fabric --version`. Ce binaire n'existe pas : les binaires sont `peer`, `orderer`, `configtxgen`…, dans `fabric-samples/bin`.
- Le réseau de test sert uniquement à apprendre : il n'est pas conçu pour la production.

## Sources

- [Installer Fabric et les exemples](https://hyperledger-fabric.readthedocs.io/en/latest/install.html)
- [Utiliser le réseau de test](https://hyperledger-fabric.readthedocs.io/en/latest/test_network.html)
