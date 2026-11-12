# openHAB — procédure d'installation

## Description

openHAB est une plateforme domotique libre, indépendante des fabricants : elle relie des centaines de technologies (Zigbee, Z-Wave, KNX, MQTT, Philips Hue…), propose des règles d'automatisation et des interfaces pour le navigateur et le téléphone. Cette procédure installe openHAB 5 depuis le dépôt officiel.

| | |
|---|---|
| **Systèmes** | Debian, Ubuntu, Raspberry Pi OS (64 bits) |
| **Méthode** | Dépôt APT officiel (`openhab.jfrog.io`), branche stable |
| **Ports** | 8080/tcp (HTTP), 8443/tcp (HTTPS) |
| **Script** | `install_openhab.sh` |

## Prérequis

- **Java 21** 64 bits (OpenJDK ou Eclipse Temurin).
- 2 Go de RAM au minimum.
- Pour un Raspberry Pi dédié, l'image openHABian (système prêt à l'emploi) est la méthode la plus simple.

## Installation automatique

```bash
git clone https://github.com/flavienxgrbld/procedures.git
cd procedures/openhab
sudo bash install_openhab.sh
```

Le script installe Java 21 (OpenJDK de la distribution, ou Eclipse Temurin 21 si elle ne le fournit pas), ajoute le dépôt openHAB (branche stable), installe `openhab` et `openhab-addons` puis démarre le service. Il reste l'assistant de l'étape 4.

## Installation manuelle

### 1. Installer Java 21

```bash
sudo apt update
sudo apt install -y openjdk-21-jre-headless
java -version
```

Si la distribution ne fournit pas Java 21, installer Eclipse Temurin 21 (dépôt `packages.adoptium.net`).

### 2. Ajouter le dépôt openHAB

```bash
curl -fsSL "https://openhab.jfrog.io/artifactory/api/gpg/key/public" | gpg --dearmor > openhab.gpg
sudo mkdir -p /usr/share/keyrings
sudo mv openhab.gpg /usr/share/keyrings/
sudo chmod u=rw,g=r,o=r /usr/share/keyrings/openhab.gpg
echo 'deb [signed-by=/usr/share/keyrings/openhab.gpg] https://openhab.jfrog.io/artifactory/openhab-linuxpkg stable main' \
  | sudo tee /etc/apt/sources.list.d/openhab.list
sudo apt update
```

### 3. Installer et démarrer openHAB

```bash
sudo apt install -y openhab openhab-addons
sudo systemctl daemon-reload
sudo systemctl enable --now openhab
sudo ufw allow 8080/tcp
```

Le premier démarrage prend plusieurs minutes.

### 4. Assistant de configuration

Ouvrir `http://<adresse-du-serveur>:8080`, créer le compte administrateur, choisir la langue, la région et la localisation, puis installer les extensions (*bindings*) correspondant aux équipements.

## Vérification

```bash
systemctl status openhab
sudo openhab-cli info
```

## Fichiers importants

| Chemin | Rôle |
|---|---|
| `/etc/openhab/` | Configuration (objets, règles, sitemaps) |
| `/var/lib/openhab/` | Données (base JSON, persistance) |
| `/var/log/openhab/openhab.log` | Journal principal |

## Dépannage

- Journal en direct : `sudo openhab-cli showlogdb` ou `tail -f /var/log/openhab/openhab.log`.
- Sauvegarde et restauration : `sudo openhab-cli backup` et `sudo openhab-cli restore <fichier>`.

## Points d'attention

- openHAB 5 demande **Java 21** ; avec Java 17, il ne démarre pas.
- Le premier démarrage prend plusieurs minutes (chargement des extensions) : attendre avant de conclure à une panne.
- Créer le compte administrateur dès l'ouverture de la page : le premier compte créé administre tout.
- Relu et mis à jour le 12/11/2026.

## Sources

- [Installer openHAB sur Linux](https://www.openhab.org/docs/installation/linux.html)
- [openHABian](https://www.openhab.org/docs/installation/openhabian.html)
