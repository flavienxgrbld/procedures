# Duplicati — procédure d'installation

## Description

Duplicati est un logiciel de sauvegarde chiffrée et incrémentale, piloté depuis une interface web. Il envoie les sauvegardes vers un disque local, un NAS, un serveur SFTP ou un stockage en ligne (S3, Backblaze B2, Google Drive…). Cette procédure installe le serveur Duplicati sur une machine Debian ou Ubuntu.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu (paquet `.deb`) ; autres distributions via l'archive `.zip` |
| **Méthode** | Paquet officiel publié sur GitHub |
| **Ports** | 8200/tcp (interface web) |
| **Script** | `install_duplicati.sh` |

## Prérequis

- Un accès root et une connexion Internet.
- Une destination de sauvegarde (disque, partage réseau ou compte de stockage en ligne).

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/duplicati
sudo bash install_duplicati.sh
```

Lire les points d'attention : le dépôt et l'archive utilisés par le script n'existent plus.

## Installation manuelle

### 1. Télécharger le paquet

Sur la page des versions de Duplicati, prendre le paquet `linux-x64-cli.deb` pour un serveur sans interface graphique (ici la version 2.4.0.1) :

```bash
cd /tmp
wget https://github.com/duplicati/duplicati/releases/download/v2.4.0.1_stable_2026-10-07/duplicati-2.4.0.1_stable_2026-10-07-linux-x64-cli.deb
```

Le paquet `linux-x64-gui.deb` ajoute une icône dans la barre des tâches, utile seulement sur un poste de travail.

### 2. Installer

```bash
sudo apt install -y ./duplicati-*-linux-x64-cli.deb
```

### 3. Démarrer le serveur au boot

```bash
sudo systemctl enable --now duplicati
systemctl list-unit-files | grep -i duplicati
```

### 4. Rendre l'interface accessible depuis le réseau

Par défaut, l'interface n'écoute que sur la machine elle-même. Pour y accéder depuis un autre poste, ajouter les options du serveur dans `/etc/default/duplicati` :

```bash
DAEMON_OPTS="--webservice-interface=any --webservice-password=MotDePasseFort"
```

```bash
sudo systemctl restart duplicati
sudo ufw allow 8200/tcp
```

### 5. Créer une sauvegarde

Ouvrir `http://<adresse-du-serveur>:8200`, puis cliquer sur **Ajouter une sauvegarde** et renseigner :

1. le nom et une **phrase de passe de chiffrement**, à conserver en lieu sûr : sans elle, aucune restauration n'est possible ;
2. la destination (dossier local, SFTP, S3, B2…), avec le bouton **Tester la connexion** ;
3. les dossiers à sauvegarder ;
4. la planification (par exemple chaque jour à 2 h) et la durée de conservation.

## Vérification

```bash
systemctl status duplicati
ss -tlnp | grep 8200
```

Lancer la sauvegarde une première fois avec **Exécuter maintenant**, puis tester une restauration d'un fichier depuis l'onglet **Restaurer**.

## Dépannage

- Interface inaccessible depuis le réseau : vérifier `--webservice-interface=any` et le pare-feu (étape 4).
- Journaux : `journalctl -u duplicati -f` et, dans l'interface, *À propos → Afficher les journaux*.

## Points d'attention

- Le script ajoute le PPA `ppa:duplicati/duplicati-releases`, qui n'existe pas (vérifié le 13/10/2026), puis tente d'installer un paquet `duplicati` absent des dépôts : l'installation échoue sur Debian et Ubuntu.
- Sur RHEL/Fedora, l'archive `v2.0.6.3` téléchargée par le script n'est plus disponible (erreur 404). Les versions récentes de Duplicati n'utilisent plus Mono.
- L'interface web sans mot de passe donne accès à toutes les sauvegardes : toujours définir `--webservice-password` si elle est exposée sur le réseau.

## Sources

- [Documentation Duplicati](https://docs.duplicati.com/)
- [Versions publiées](https://github.com/duplicati/duplicati/releases)
