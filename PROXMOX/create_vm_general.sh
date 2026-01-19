#!/bin/bash

###############################################################################
# Script de création de VM Proxmox
# Usage: ./create_vm.sh
###############################################################################

set -e  # Arrêter le script en cas d'erreur

# ========== SAISIE DES INFORMATIONS ==========

echo "=========================================="
echo "Création de VM Proxmox"
echo "=========================================="
echo ""

# Paramètres de la VM
read -p "ID de la VM (ex: 100): " VMID
while [[ ! "$VMID" =~ ^[0-9]+$ ]]; do
    echo "Erreur: L'ID doit être un nombre"
    read -p "ID de la VM (ex: 100): " VMID
done

read -p "Nom de la VM (ex: vm-test): " VM_NAME
while [[ -z "$VM_NAME" ]]; do
    echo "Erreur: Le nom ne peut pas être vide"
    read -p "Nom de la VM (ex: vm-test): " VM_NAME
done

read -p "Nombre de CPU cores (défaut: 2): " CORES
CORES=${CORES:-2}

read -p "RAM en MB (défaut: 2048): " MEMORY
MEMORY=${MEMORY:-2048}

read -p "Taille du disque (ex: 20G, défaut: 20G): " DISK_SIZE
DISK_SIZE=${DISK_SIZE:-20G}

read -p "Stockage pour le disque (défaut: local-lvm): " STORAGE
STORAGE=${STORAGE:-local-lvm}

read -p "Bridge réseau (défaut: vmbr0): " BRIDGE
BRIDGE=${BRIDGE:-vmbr0}

# Paramètres réseau
echo ""
echo "Configuration réseau (laisser vide pour DHCP):"
read -p "Adresse IP avec masque (ex: 192.168.1.100/24): " IP_ADDRESS

if [[ -n "$IP_ADDRESS" ]]; then
    read -p "Passerelle (ex: 192.168.1.1): " GATEWAY
    read -p "Serveur DNS (ex: 8.8.8.8): " DNS
else
    GATEWAY=""
    DNS=""
fi

# ISO ou template
echo ""
read -p "Stockage de l'ISO (défaut: local): " ISO_STORAGE
ISO_STORAGE=${ISO_STORAGE:-local}

echo "ISOs disponibles dans $ISO_STORAGE:"
pvesm list $ISO_STORAGE | grep iso || echo "Aucune ISO trouvée"
echo ""
read -p "Nom du fichier ISO: " ISO_FILE
while [[ -z "$ISO_FILE" ]]; do
    echo "Erreur: Le nom de l'ISO ne peut pas être vide"
    read -p "Nom du fichier ISO: " ISO_FILE
done

# Autres options
echo ""
read -p "Démarrer au boot du serveur? (y/n, défaut: n): " START_ON_BOOT_INPUT
if [[ "$START_ON_BOOT_INPUT" =~ ^[Yy]$ ]]; then
    START_ON_BOOT=1
else
    START_ON_BOOT=0
fi

read -p "Démarrer la VM après création? (y/n, défaut: n): " START_AFTER_CREATE_INPUT
if [[ "$START_AFTER_CREATE_INPUT" =~ ^[Yy]$ ]]; then
    START_AFTER_CREATE=1
else
    START_AFTER_CREATE=0
fi

# ========== VÉRIFICATIONS ==========

echo ""
echo "=========================================="
echo "Vérification des paramètres..."
echo "=========================================="
echo ""

# Vérifier si la VM existe déjà
if qm status $VMID &>/dev/null; then
    echo "Erreur: Une VM avec l'ID $VMID existe déjà!"
    exit 1
fi

# Vérifier si l'ISO existe
if ! pvesm list $ISO_STORAGE | grep -q "$ISO_FILE"; then
    echo "Avertissement: L'ISO $ISO_FILE n'a pas été trouvé dans $ISO_STORAGE"
    echo "Vérifiez le nom du fichier ISO ou utilisez:"
    echo "  pvesm list $ISO_STORAGE"
    read -p "Continuer quand même? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# ========== CRÉATION DE LA VM ==========

echo "Création de la VM $VMID ($VM_NAME)..."

# Créer la VM de base
qm create $VMID \
    --name $VM_NAME \
    --cores $CORES \
    --memory $MEMORY \
    --net0 virtio,bridge=$BRIDGE \
    --scsihw virtio-scsi-pci \
    --ostype l26

echo "✓ VM de base créée"

# Ajouter le disque
qm set $VMID \
    --scsi0 $STORAGE:$DISK_SIZE

echo "✓ Disque ajouté ($DISK_SIZE sur $STORAGE)"

# Monter l'ISO
qm set $VMID \
    --ide2 $ISO_STORAGE:iso/$ISO_FILE,media=cdrom

echo "✓ ISO monté ($ISO_FILE)"

# Configurer le boot
qm set $VMID \
    --boot order=scsi0\;ide2

echo "✓ Ordre de boot configuré"

# Configurer l'agent QEMU (optionnel)
qm set $VMID \
    --agent enabled=1

echo "✓ Agent QEMU activé"

# Configuration réseau statique (si spécifié)
if [ -n "$IP_ADDRESS" ]; then
    qm set $VMID --ipconfig0 ip=$IP_ADDRESS
    if [ -n "$GATEWAY" ]; then
        qm set $VMID --ipconfig0 ip=$IP_ADDRESS,gw=$GATEWAY
    fi
    echo "✓ Configuration réseau statique: $IP_ADDRESS"
fi

# Configuration DNS (si spécifié)
if [ -n "$DNS" ]; then
    qm set $VMID --nameserver $DNS
    echo "✓ DNS configuré: $DNS"
fi

# Démarrage au boot
if [ $START_ON_BOOT -eq 1 ]; then
    qm set $VMID --onboot 1
    echo "✓ Démarrage au boot activé"
fi

# ========== RÉSUMÉ ==========

echo ""
echo "=========================================="
echo "VM créée avec succès!"
echo "=========================================="
echo "ID:         $VMID"
echo "Nom:        $VM_NAME"
echo "CPU:        $CORES cores"
echo "RAM:        $MEMORY MB"
echo "Disque:     $DISK_SIZE sur $STORAGE"
echo "Réseau:     $BRIDGE"
echo "ISO:        $ISO_FILE"
echo ""

# Afficher la configuration complète
echo "Configuration complète:"
qm config $VMID

# ========== DÉMARRAGE (optionnel) ==========

if [ $START_AFTER_CREATE -eq 1 ]; then
    echo ""
    echo "Démarrage de la VM..."
    qm start $VMID
    echo "✓ VM démarrée"
    echo ""
    echo "Pour vous connecter à la console:"
    echo "  - Interface Web: https://your-proxmox-host:8006"
    echo "  - Console: qm terminal $VMID"
else
    echo ""
    echo "Pour démarrer la VM manuellement:"
    echo "  qm start $VMID"
    echo ""
    echo "Pour vous connecter à la console:"
    echo "  qm terminal $VMID"
fi

echo ""
echo "Autres commandes utiles:"
echo "  qm status $VMID          # Vérifier le statut"
echo "  qm stop $VMID            # Arrêter la VM"
echo "  qm shutdown $VMID        # Arrêter proprement"
echo "  qm destroy $VMID         # Supprimer la VM"
echo "  qm list                  # Lister toutes les VMs"
