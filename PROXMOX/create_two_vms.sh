#!/bin/bash

###############################################################################
# Script de création de deux VM Proxmox prédéfinies
# Usage: ./create_two_vms.sh
###############################################################################

set -e  # Arrêter le script en cas d'erreur

# ========== CONFIGURATION VM 1 ==========
VM1_ID=901
VM1_NAME="vm-web"
VM1_CORES=2
VM1_MEMORY=4096
VM1_DISK_SIZE="30G"
VM1_STORAGE="local-lvm"
VM1_BRIDGE="vmbr0"
VM1_IP=""  # Laisser vide pour DHCP ou ex: 192.168.1.101/24
VM1_GATEWAY=""
VM1_DNS=""
VM1_ISO_STORAGE="local"
VM1_ISO_FILE="ubuntu-22.04-server-amd64.iso"
VM1_START_ON_BOOT=1

# ========== CONFIGURATION VM 2 ==========
VM2_ID=902
VM2_NAME="vm-database"
VM2_CORES=4
VM2_MEMORY=4096
VM2_DISK_SIZE="30G"
VM2_STORAGE="local-lvm"
VM2_BRIDGE="vmbr0"
VM2_IP=""  # Laisser vide pour DHCP ou ex: 192.168.1.102/24
VM2_GATEWAY=""
VM2_DNS=""
VM2_ISO_STORAGE="local"
VM2_ISO_FILE="ubuntu-22.04-server-amd64.iso"
VM2_START_ON_BOOT=1

# ========== FONCTION DE SÉLECTION D'ISO ==========

select_iso() {
    local ISO_STORAGE=$1
    local VM_NAME=$2
    
    echo ""
    echo "========================================="
    echo "Sélection de l'ISO pour $VM_NAME"
    echo "========================================="
    echo ""
    
    # Récupérer la liste des ISOs
    local ISO_LIST=()
    while IFS= read -r line; do
        if [[ $line == *".iso"* ]]; then
            # Extraire uniquement le nom du fichier ISO
            local iso_name=$(echo "$line" | awk '{print $1}' | grep -o '[^/]*\.iso$')
            if [[ -n "$iso_name" ]]; then
                ISO_LIST+=("$iso_name")
            fi
        fi
    done < <(pvesm list "$ISO_STORAGE" 2>/dev/null | grep -i iso)
    
    # Vérifier s'il y a des ISOs disponibles
    if [ ${#ISO_LIST[@]} -eq 0 ]; then
        echo "❌ Aucune ISO trouvée dans le stockage $ISO_STORAGE"
        echo "Veuillez télécharger une ISO d'abord."
        exit 1
    fi
    
    # Afficher la liste des ISOs
    echo "ISOs disponibles:"
    for i in "${!ISO_LIST[@]}"; do
        echo "  $((i+1)). ${ISO_LIST[$i]}"
    done
    echo ""
    
    # Demander à l'utilisateur de choisir
    local choice
    while true; do
        read -p "Choisissez le numéro de l'ISO (1-${#ISO_LIST[@]}): " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#ISO_LIST[@]} ]; then
            echo "${ISO_LIST[$((choice-1))]}"
            return 0
        else
            echo "❌ Choix invalide. Veuillez entrer un numéro entre 1 et ${#ISO_LIST[@]}"
        fi
    done
}

# ========== FONCTION DE CRÉATION DE VM ==========

create_vm() {
    local VMID=$1
    local VM_NAME=$2
    local CORES=$3
    local MEMORY=$4
    local DISK_SIZE=$5
    local STORAGE=$6
    local BRIDGE=$7
    local IP_ADDRESS=$8
    local GATEWAY=$9
    local DNS=${10}
    local ISO_STORAGE=${11}
    local ISO_FILE=${12}
    local START_ON_BOOT=${13}

    echo ""
    echo "=========================================="
    echo "Création de la VM $VMID ($VM_NAME)"
    echo "=========================================="
    
    # Vérifier si la VM existe déjà
    if qm status $VMID &>/dev/null; then
        echo "⚠️  Avertissement: Une VM avec l'ID $VMID existe déjà!"
        read -p "Voulez-vous la supprimer et la recréer? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Suppression de la VM existante..."
            qm stop $VMID 2>/dev/null || true
            sleep 2
            qm destroy $VMID
            echo "✓ VM supprimée"
        else
            echo "⏭️  Saut de la VM $VMID"
            return 0
        fi
    fi

    # Créer la VM de base
    echo "Création de la VM de base..."
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

    # Configurer l'agent QEMU
    qm set $VMID \
        --agent enabled=1

    echo "✓ Agent QEMU activé"

    # Configuration réseau statique (si spécifié)
    if [ -n "$IP_ADDRESS" ]; then
        if [ -n "$GATEWAY" ]; then
            qm set $VMID --ipconfig0 ip=$IP_ADDRESS,gw=$GATEWAY
        else
            qm set $VMID --ipconfig0 ip=$IP_ADDRESS
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

    echo ""
    echo "✅ VM $VMID ($VM_NAME) créée avec succès!"
    echo "   CPU: $CORES cores | RAM: $MEMORY MB | Disque: $DISK_SIZE"
}

# ========== SCRIPT PRINCIPAL ==========

echo "=========================================="
echo "Création de deux VM Proxmox"
echo "=========================================="
echo ""
echo "Ce script va créer les VMs suivantes:"
echo ""
echo "VM 1:"
echo "  - ID: $VM1_ID"
echo "  - Nom: $VM1_NAME"
echo "  - CPU: $VM1_CORES cores"
echo "  - RAM: $VM1_MEMORY MB"
echo "  - Disque: $VM1_DISK_SIZE"
echo ""
echo "VM 2:"
echo "  - ID: $VM2_ID"
echo "  - Nom: $VM2_NAME"
echo "  - CPU: $VM2_CORES cores"
echo "  - RAM: $VM2_MEMORY MB"
echo "  - Disque: $VM2_DISK_SIZE"
echo ""

read -p "Continuer? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Annulé par l'utilisateur"
    exit 0
fi

# Sélectionner l'ISO pour VM1
VM1_ISO_FILE=$(select_iso "$VM1_ISO_STORAGE" "$VM1_NAME")
echo "✓ ISO sélectionnée pour VM1: $VM1_ISO_FILE"

# Créer la première VM
create_vm "$VM1_ID" "$VM1_NAME" "$VM1_CORES" "$VM1_MEMORY" "$VM1_DISK_SIZE" \
    "$VM1_STORAGE" "$VM1_BRIDGE" "$VM1_IP" "$VM1_GATEWAY" "$VM1_DNS" \
    "$VM1_ISO_STORAGE" "$VM1_ISO_FILE" "$VM1_START_ON_BOOT"

# Sélectionner l'ISO pour VM2
VM2_ISO_FILE=$(select_iso "$VM2_ISO_STORAGE" "$VM2_NAME")
echo "✓ ISO sélectionnée pour VM2: $VM2_ISO_FILE"

# Créer la deuxième VM
create_vm "$VM2_ID" "$VM2_NAME" "$VM2_CORES" "$VM2_MEMORY" "$VM2_DISK_SIZE" \
    "$VM2_STORAGE" "$VM2_BRIDGE" "$VM2_IP" "$VM2_GATEWAY" "$VM2_DNS" \
    "$VM2_ISO_STORAGE" "$VM2_ISO_FILE" "$VM2_START_ON_BOOT"

# ========== RÉSUMÉ FINAL ==========

echo ""
echo "=========================================="
echo "✅ Toutes les VMs ont été créées!"
echo "=========================================="
echo ""
echo "Liste des VMs créées:"
qm list | grep -E "($VM1_ID|$VM2_ID)"
echo ""
echo "Pour démarrer les VMs:"
echo "  qm start $VM1_ID  # Démarrer $VM1_NAME"
echo "  qm start $VM2_ID  # Démarrer $VM2_NAME"
echo ""
echo "Pour vous connecter aux consoles:"
echo "  qm terminal $VM1_ID  # Console $VM1_NAME"
echo "  qm terminal $VM2_ID  # Console $VM2_NAME"
echo ""
echo "Interface Web: https://your-proxmox-host:8006"
