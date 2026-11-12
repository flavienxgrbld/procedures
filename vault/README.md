# HashiCorp Vault — procédure d'installation

## Description

Vault centralise et protège les secrets : mots de passe, clés d'API, certificats, identifiants de base de données. Il les chiffre, contrôle qui y accède (politiques), trace chaque accès et peut générer des secrets temporaires. Cette procédure installe un serveur Vault autonome depuis le dépôt officiel, avec stockage intégré (Raft).

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu (dépôt HashiCorp) |
| **Méthode** | Dépôt APT officiel HashiCorp |
| **Ports** | 8200/tcp (API et interface), 8201/tcp (cluster) |
| **Script** | `install_vault.sh` |

## Prérequis

- Un accès root et une connexion Internet.
- Un certificat TLS pour la production (sans TLS, les secrets circulent en clair sur le réseau).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/vault
sudo bash install_vault.sh
```

Le script ajoute le dépôt HashiCorp, installe Vault, génère un certificat autosigné valable pour l'adresse du serveur, écrit la configuration de l'étape 2 (stockage Raft, TLS, `api_addr`), démarre le service, puis **initialise** Vault (5 clés, 3 nécessaires) et le descelle. Les clés et le jeton root sont enregistrés dans `/root/vault_init.json` (600) : les distribuer puis supprimer ce fichier. Variables facultatives : `VAULT_ADDR_IP`, `VAULT_SHARES`, `VAULT_THRESHOLD`.

## Installation manuelle

### 1. Installer Vault

```bash
sudo apt update
sudo apt install -y gpg wget
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt install -y vault
```

Le paquet crée l'utilisateur `vault`, le service et un certificat autosigné dans `/opt/vault/tls/`.

### 2. Configurer

`/etc/vault.d/vault.hcl` :

```hcl
ui = true

storage "raft" {
  path    = "/opt/vault/data"
  node_id = "vault1"
}

listener "tcp" {
  address       = "0.0.0.0:8200"
  tls_cert_file = "/opt/vault/tls/tls.crt"
  tls_key_file  = "/opt/vault/tls/tls.key"
}

api_addr     = "https://192.168.1.80:8200"
cluster_addr = "https://192.168.1.80:8201"
```

Remplacer `192.168.1.80` par l'adresse du serveur, et le certificat autosigné par un vrai certificat en production.

```bash
sudo systemctl enable --now vault
sudo ufw allow from 192.168.1.0/24 to any port 8200 proto tcp
```

### 3. Initialiser et déverrouiller

```bash
export VAULT_ADDR=https://127.0.0.1:8200
export VAULT_SKIP_VERIFY=true       # uniquement avec le certificat autosigné
vault operator init
```

La commande affiche **5 clés de déverrouillage** et le **jeton root**. Les conserver séparément et en lieu sûr : sans 3 de ces 5 clés, les données sont définitivement inaccessibles.

```bash
vault operator unseal      # répéter 3 fois avec 3 clés différentes
vault login                # avec le jeton root
```

### 4. Stocker un premier secret

```bash
vault secrets enable -path=secret kv-v2
vault kv put secret/appli/bdd utilisateur=appli motdepasse=MotDePasseFort
vault kv get secret/appli/bdd
```

L'interface web est accessible sur `https://<adresse-du-serveur>:8200/ui`.

## Vérification

```bash
vault status
```

`Sealed` doit valoir `false` après le déverrouillage. Après chaque redémarrage, Vault redevient verrouillé et doit être déverrouillé à nouveau (ou configuré en déverrouillage automatique).

## Points d'attention

- Le jeton root et les clés de descellement réunis donnent accès à tous les secrets : ne pas les laisser sur le serveur (le script les écrit dans `/root/vault_init.json` pour les récupérer, à supprimer ensuite).
- Après chaque redémarrage, Vault est **scellé** : le desceller avec `vault operator unseal` (3 clés différentes).
- Le jeton root ne sert qu'à la configuration initiale : créer ensuite des politiques et des méthodes d'authentification dédiées, puis révoquer le jeton root.
- En production, remplacer le certificat autosigné par un vrai certificat.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Installer Vault](https://developer.hashicorp.com/vault/docs/install)
- [Déployer Vault (tutoriel)](https://developer.hashicorp.com/vault/tutorials/getting-started/getting-started-deploy)
