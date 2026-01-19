#!/bin/bash

###############################################################################
# Script de création de cinq VM Proxmox prédéfinies
# Usage: ./create_five_vms.sh
###############################################################################

set -e  # Arrêter le script en cas d'erreur

# ========== CONFIGURATION VM 1 ==========
VM1_ID=101
VM1_NAME="SRV-AD1EX"
VM1_CORES=4
VM1_MEMORY=24000
VM1_DISK_SIZE="120G"
VM1_STORAGE="local-lvm"
VM1_BRIDGE="vmbr0"
VM1_IP=""  # Laisser vide pour DHCP ou ex: 192.168.1.101/24
VM1_GATEWAY=""
VM1_DNS=""
VM1_ISO_STORAGE="local"
VM1_START_ON_BOOT=1
VM1_OS_TYPE="win11"  # win11 pour Windows

# ========== CONFIGURATION VM 2 ==========
VM2_ID=102
VM2_NAME="SRV-AD2"
VM2_CORES=2
VM2_MEMORY=8192
VM2_DISK_SIZE="120G"
VM2_STORAGE="local-lvm"
VM2_BRIDGE="vmbr0"
VM2_IP=""
VM2_GATEWAY=""
VM2_DNS=""
VM2_ISO_STORAGE="local"
VM2_START_ON_BOOT=0
VM2_OS_TYPE="win11"  # win11 pour Windows

# ========== CONFIGURATION VM 3 ==========
VM3_ID=103
VM3_NAME="SRV-GLPI"
VM3_CORES=2
VM3_MEMORY=4096
VM3_DISK_SIZE="50G"
VM3_STORAGE="local-lvm"
VM3_BRIDGE="vmbr0"
VM3_IP=""
VM3_GATEWAY=""
VM3_DNS=""
VM3_ISO_STORAGE="local"
VM3_START_ON_BOOT=0
VM3_OS_TYPE="l26"  # l26 pour Linux

# ========== CONFIGURATION VM 4 ==========
VM4_ID=104
VM4_NAME="SRV-ZABBIX"
VM4_CORES=2
VM4_MEMORY=4096
VM4_DISK_SIZE="50G"
VM4_STORAGE="local-lvm"
VM4_BRIDGE="vmbr0"
VM4_IP=""
VM4_GATEWAY=""
VM4_DNS=""
VM4_ISO_STORAGE="local"
VM4_START_ON_BOOT=0
VM4_OS_TYPE="l26"  # l26 pour Linux

# ========== CONFIGURATION VM 5 ==========
VM5_ID=110
VM5_NAME="W11-CLIENT"
VM5_CORES=2
VM5_MEMORY=8000
VM5_DISK_SIZE="80G"
VM5_STORAGE="local-lvm"
VM5_BRIDGE="vmbr0"
VM5_IP=""
VM5_GATEWAY=""
VM5_DNS=""
VM5_ISO_STORAGE="local"
VM5_START_ON_BOOT=0
VM5_OS_TYPE="win11"  # win11 pour Windows

# ========== FONCTION DE SÉLECTION D'ISO ==========

select_iso() {
    local ISO_STORAGE=$1
    local VM_NAME=$2
    
    echo ""
    echo "=========================================="
    echo "Sélection de l'ISO pour $VM_NAME"
    echo "=========================================="
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
    local OS_TYPE=${14}

    echo ""
    echo "=========================================="
    echo "Création de la VM $VMID ($VM_NAME)"
    echo "Type: $OS_TYPE"
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

    # Configuration spécifique selon le type d'OS
    if [[ "$OS_TYPE" == "win11" ]]; then
        # Configuration pour Windows avec UEFI, TPM et Secure Boot
        echo "Configuration Windows avec UEFI, TPM et Secure Boot..."
        
        # Créer la VM Windows
        qm create $VMID \
            --name $VM_NAME \
            --cores $CORES \
            --memory $MEMORY \
            --net0 virtio,bridge=$BRIDGE \
            --ostype win11 \
            --machine q35 \
            --bios ovmf \
            --cpu host \
            --sockets 1
        
        echo "✓ VM Windows de base créée"
        
        # Ajouter le disque EFI pour UEFI
        qm set $VMID --efidisk0 $STORAGE:1,efitype=4m,pre-enrolled-keys=1
        echo "✓ Disque EFI ajouté (Secure Boot activé)"
        
        # Ajouter le TPM 2.0
        qm set $VMID --tpmstate0 $STORAGE:1,version=v2.0
        echo "✓ TPM 2.0 ajouté"
        
        # Ajouter le disque principal en SATA avec émulation SSD
        qm set $VMID --sata0 $STORAGE:$DISK_SIZE,cache=writeback,discard=on,ssd=1
        echo "✓ Disque principal SATA ajouté avec émulation SSD ($DISK_SIZE sur $STORAGE)"
        
        # Monter l'ISO Windows
        qm set $VMID --ide2 $ISO_STORAGE:iso/$ISO_FILE,media=cdrom
        echo "✓ ISO Windows monté ($ISO_FILE)"
        
        # Note: Ajouter les drivers VirtIO si disponible
        echo "ℹ️  Note: Pensez à monter l'ISO VirtIO drivers pour l'installation Windows"
        echo "   Commande: qm set $VMID --ide0 local:iso/virtio-win.iso,media=cdrom"
        
        # Configurer le boot
        qm set $VMID --boot order=sata0\;ide2
        echo "✓ Ordre de boot configuré (SATA + SSD emulation)"
        
        # Agent QEMU pour Windows (sera disponible après installation de qemu-guest-agent)
        qm set $VMID --agent enabled=1,fstrim_cloned_disks=1
        echo "✓ Agent QEMU configuré (installer qemu-guest-agent dans Windows)"
        
    else
        # Configuration pour Linux
        echo "Configuration Linux standard..."
        
        qm create $VMID \
            --name $VM_NAME \
            --cores $CORES \
            --memory $MEMORY \
            --net0 virtio,bridge=$BRIDGE \
            --ostype l26

        echo "✓ VM Linux de base créée"

        # Ajouter le disque en SATA avec émulation SSD
        qm set $VMID \
            --sata0 $STORAGE:$DISK_SIZE,ssd=1

        echo "✓ Disque SATA ajouté avec émulation SSD ($DISK_SIZE sur $STORAGE)"

        # Monter l'ISO
        qm set $VMID \
            --ide2 $ISO_STORAGE:iso/$ISO_FILE,media=cdrom

        echo "✓ ISO monté ($ISO_FILE)"

        # Configurer le boot
        qm set $VMID \
            --boot order=sata0\;ide2

        echo "✓ Ordre de boot configuré (SATA + SSD emulation)"

        # Configurer l'agent QEMU
        qm set $VMID \
            --agent enabled=1

        echo "✓ Agent QEMU activé"
    fi

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
    if [[ "$OS_TYPE" == "win11" ]]; then
        echo "   Type: Windows 11 (UEFI + TPM 2.0 + Secure Boot)"
    else
        echo "   Type: Linux"
    fi
    echo "   CPU: $CORES cores | RAM: $MEMORY MB | Disque: $DISK_SIZE"
}

# ========== SCRIPT PRINCIPAL ==========

echo "=========================================="
echo "Création de cinq VM Proxmox"
echo "=========================================="
echo ""
echo "Ce script va créer les VMs suivantes:"
echo ""
echo "VM 1: $VM1_NAME (ID: $VM1_ID) - $VM1_CORES CPU, $VM1_MEMORY MB RAM, $VM1_DISK_SIZE disque"
echo "VM 2: $VM2_NAME (ID: $VM2_ID) - $VM2_CORES CPU, $VM2_MEMORY MB RAM, $VM2_DISK_SIZE disque"
echo "VM 3: $VM3_NAME (ID: $VM3_ID) - $VM3_CORES CPU, $VM3_MEMORY MB RAM, $VM3_DISK_SIZE disque"
echo "VM 4: $VM4_NAME (ID: $VM4_ID) - $VM4_CORES CPU, $VM4_MEMORY MB RAM, $VM4_DISK_SIZE disque"
echo "VM 5: $VM5_NAME (ID: $VM5_ID) - $VM5_CORES CPU, $VM5_MEMORY MB RAM, $VM5_DISK_SIZE disque"
echo ""

read -p "Continuer? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Annulé par l'utilisateur"
    exit 0
fi

# Sélectionner l'ISO pour chaque VM
echo ""
echo "=========================================="
echo "Sélection des ISOs"
echo "=========================================="

VM1_ISO_FILE=$(select_iso "$VM1_ISO_STORAGE" "$VM1_NAME")
echo "✓ ISO sélectionnée pour VM1: $VM1_ISO_FILE"

VM2_ISO_FILE=$(select_iso "$VM2_ISO_STORAGE" "$VM2_NAME")
echo "✓ ISO sélectionnée pour VM2: $VM2_ISO_FILE"

VM3_ISO_FILE=$(select_iso "$VM3_ISO_STORAGE" "$VM3_NAME")
echo "✓ ISO sélectionnée pour VM3: $VM3_ISO_FILE"

VM4_ISO_FILE=$(select_iso "$VM4_ISO_STORAGE" "$VM4_NAME")
echo "✓ ISO sélectionnée pour VM4: $VM4_ISO_FILE"

VM5_ISO_FILE=$(select_iso "$VM5_ISO_STORAGE" "$VM5_NAME")
echo "✓ ISO sélectionnée pour VM5: $VM5_ISO_FILE"

# Créer les cinq VMs
create_vm "$VM1_ID" "$VM1_NAME" "$VM1_CORES" "$VM1_MEMORY" "$VM1_DISK_SIZE" \
    "$VM1_STORAGE" "$VM1_BRIDGE" "$VM1_IP" "$VM1_GATEWAY" "$VM1_DNS" \
    "$VM1_ISO_STORAGE" "$VM1_ISO_FILE" "$VM1_START_ON_BOOT" "$VM1_OS_TYPE"

create_vm "$VM2_ID" "$VM2_NAME" "$VM2_CORES" "$VM2_MEMORY" "$VM2_DISK_SIZE" \
    "$VM2_STORAGE" "$VM2_BRIDGE" "$VM2_IP" "$VM2_GATEWAY" "$VM2_DNS" \
    "$VM2_ISO_STORAGE" "$VM2_ISO_FILE" "$VM2_START_ON_BOOT" "$VM2_OS_TYPE"

create_vm "$VM3_ID" "$VM3_NAME" "$VM3_CORES" "$VM3_MEMORY" "$VM3_DISK_SIZE" \
    "$VM3_STORAGE" "$VM3_BRIDGE" "$VM3_IP" "$VM3_GATEWAY" "$VM3_DNS" \
    "$VM3_ISO_STORAGE" "$VM3_ISO_FILE" "$VM3_START_ON_BOOT" "$VM3_OS_TYPE"

create_vm "$VM4_ID" "$VM4_NAME" "$VM4_CORES" "$VM4_MEMORY" "$VM4_DISK_SIZE" \
    "$VM4_STORAGE" "$VM4_BRIDGE" "$VM4_IP" "$VM4_GATEWAY" "$VM4_DNS" \
    "$VM4_ISO_STORAGE" "$VM4_ISO_FILE" "$VM4_START_ON_BOOT" "$VM4_OS_TYPE"

create_vm "$VM5_ID" "$VM5_NAME" "$VM5_CORES" "$VM5_MEMORY" "$VM5_DISK_SIZE" \
    "$VM5_STORAGE" "$VM5_BRIDGE" "$VM5_IP" "$VM5_GATEWAY" "$VM5_DNS" \
    "$VM5_ISO_STORAGE" "$VM5_ISO_FILE" "$VM5_START_ON_BOOT" "$VM5_OS_TYPE"

# ========== RÉSUMÉ FINAL ==========

echo ""
echo "=========================================="
echo "✅ Toutes les VMs ont été créées!"
echo "=========================================="
echo ""
echo "Liste des VMs créées:"
qm list | grep -E "($VM1_ID|$VM2_ID|$VM3_ID|$VM4_ID|$VM5_ID)"
echo ""
echo "Pour démarrer les VMs:"
echo "  qm start $VM1_ID  # Démarrer $VM1_NAME"
echo "  qm start $VM2_ID  # Démarrer $VM2_NAME"
echo "  qm start $VM3_ID  # Démarrer $VM3_NAME"
echo "  qm start $VM4_ID  # Démarrer $VM4_NAME"
echo "  qm start $VM5_ID  # Démarrer $VM5_NAME"
echo ""
echo "Pour vous connecter aux consoles:"
echo "  qm terminal <VMID>"
echo ""
echo "Interface Web: https://your-proxmox-host:8006"
