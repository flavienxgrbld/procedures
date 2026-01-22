#!/bin/bash

###############################################################################
# Script de création de cinq VM Proxmox prédéfinies
# Usage: ./create_five_vms.sh
###############################################################################

set -e  # Arrêter le script en cas d'erreur

# ========== MODE AUTOMATIQUE ==========
AUTO_MODE=1  # 1 = aucune interaction, 0 = mode interactif
AUTO_RECREATE_VMS=1  # 1 = supprimer et recréer les VMs existantes automatiquement
AUTO_RECREATE_TEMPLATE=0  # 1 = recréer le template s'il existe, 0 = réutiliser l'existant

# ========== CONFIGURATION CLOUD-INIT (pour VMs Linux) ==========
CLOUD_INIT_TEMPLATE_ID=9000  # ID du template cloud-init
CLOUD_INIT_USER="sio"
CLOUD_INIT_PASSWORD="Azerty13."  # À changer!
CLOUD_INIT_SSH_KEY=""  # Chemin vers votre clé SSH publique (ex: ~/.ssh/id_rsa.pub) ou laisser vide
CLOUD_INIT_DISTRO="ubuntu2204"  # Distribution pour cloud-init: ubuntu2204, ubuntu2404, debian12, debian13

# ========== CONFIGURATION DES ISOs PAR DÉFAUT ==========
# Noms des fichiers ISO à utiliser (laisser vide pour auto-détection)
VM1_ISO_NAME=""  # Ex: "Windows_Server_2022.iso" ou vide pour prendre la première ISO Windows trouvée
VM2_ISO_NAME=""  # Ex: "Windows_Server_2022.iso" ou vide
VM5_ISO_NAME=""  # Ex: "Windows_11.iso" ou vide

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
VM1_OS_TYPE="win11"  # win11 pour Windows Server 2022

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
VM2_OS_TYPE="win11"  # win11 pour Windows Server 2022

# ========== CONFIGURATION VM 3 ==========
VM3_ID=103
VM3_NAME="SRV-GLPI"
VM3_CORES=2
VM3_MEMORY=4096
VM3_DISK_SIZE="50G"
VM3_STORAGE="local-lvm"
VM3_BRIDGE="vmbr0"
VM3_IP="192.168.1.103/24"  # IP statique (ou "dhcp" pour DHCP)
VM3_GATEWAY="192.168.1.1"
VM3_DNS="8.8.8.8"
VM3_ISO_STORAGE="local"
VM3_START_ON_BOOT=0
VM3_OS_TYPE="l26"  # l26 pour Linux
VM3_USE_CLOUD_INIT=1  # 1 = cloud-init, 0 = ISO

# ========== CONFIGURATION VM 4 ==========
VM4_ID=104
VM4_NAME="SRV-ZABBIX"
VM4_CORES=2
VM4_MEMORY=4096
VM4_DISK_SIZE="50G"
VM4_STORAGE="local-lvm"
VM4_BRIDGE="vmbr0"
VM4_IP="192.168.1.104/24"  # IP statique (ou "dhcp" pour DHCP)
VM4_GATEWAY="192.168.1.1"
VM4_DNS="8.8.8.8"
VM4_ISO_STORAGE="local"
VM4_START_ON_BOOT=0
VM4_OS_TYPE="l26"  # l26 pour Linux
VM4_USE_CLOUD_INIT=1  # 1 = cloud-init, 0 = ISO

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
VM5_OS_TYPE="win11"  # win11 pour Windows 11

# ========== FONCTION DE CRÉATION DU TEMPLATE CLOUD-INIT ==========

create_cloud_init_template() {
    echo ""
    echo "=========================================="
    echo "Configuration du template cloud-init"
    echo "=========================================="
    echo ""
    
    # Vérifier si le template existe déjà
    if qm status $CLOUD_INIT_TEMPLATE_ID &>/dev/null; then
        echo "✓ Le template cloud-init $CLOUD_INIT_TEMPLATE_ID existe déjà"
        if [ $AUTO_RECREATE_TEMPLATE -eq 1 ]; then
            echo "Mode automatique: suppression du template existant..."
            qm destroy $CLOUD_INIT_TEMPLATE_ID
            echo "✓ Template supprimé"
        else
            echo "⏭️  Utilisation du template existant (AUTO_RECREATE_TEMPLATE=0)"
            return 0
        fi
    fi
    
    # Sélection automatique de la distribution
    local image_url
    local image_name
    local distro_name
    
    case $CLOUD_INIT_DISTRO in
        ubuntu2204)
            image_url="https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
            image_name="ubuntu-22.04-cloudimg.img"
            distro_name="Ubuntu 22.04 LTS"
            ;;
        ubuntu2404)
            image_url="https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img"
            image_name="ubuntu-24.04-cloudimg.img"
            distro_name="Ubuntu 24.04 LTS"
            ;;
        debian12)
            image_url="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
            image_name="debian-12-cloudimg.qcow2"
            distro_name="Debian 12"
            ;;
        debian13)
            image_url="https://cloud.debian.org/images/cloud/trixie/daily/latest/debian-13-generic-amd64-daily.qcow2"
            image_name="debian-13-cloudimg.qcow2"
            distro_name="Debian 13"
            ;;
        *)
            echo "❌ Distribution invalide: $CLOUD_INIT_DISTRO"
            echo "   Valeurs acceptées: ubuntu2204, ubuntu2404, debian12, debian13"
            exit 1
            ;;
    esac
    
    echo "Distribution sélectionnée: $distro_name"
    
    echo ""
    echo "Téléchargement de l'image cloud..."
    echo "URL: $image_url"
    
    # Créer un dossier temporaire
    local temp_dir="/tmp/cloud-init-template"
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # Télécharger l'image
    if ! wget -q --show-progress "$image_url" -O "$image_name"; then
        echo "❌ Erreur lors du téléchargement de l'image"
        cd -
        rm -rf "$temp_dir"
        return 1
    fi
    
    echo "✓ Image téléchargée"
    
    # Créer la VM template
    echo ""
    echo "Création du template cloud-init (ID: $CLOUD_INIT_TEMPLATE_ID)..."
    
    qm create $CLOUD_INIT_TEMPLATE_ID \
        --name "cloud-init-template" \
        --memory 2048 \
        --cores 2 \
        --net0 virtio,bridge=vmbr0 \
        --ostype l26
    
    echo "✓ VM de base créée"
    
    # Importer le disque
    qm importdisk $CLOUD_INIT_TEMPLATE_ID "$image_name" local-lvm
    echo "✓ Disque importé"
    
    # Configurer le disque
    qm set $CLOUD_INIT_TEMPLATE_ID --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-$CLOUD_INIT_TEMPLATE_ID-disk-0
    echo "✓ Disque SCSI configuré"
    
    # Ajouter le disque cloud-init
    qm set $CLOUD_INIT_TEMPLATE_ID --ide2 local-lvm:cloudinit
    echo "✓ Disque cloud-init ajouté"
    
    # Configurer le boot
    qm set $CLOUD_INIT_TEMPLATE_ID --boot c --bootdisk scsi0
    echo "✓ Boot configuré"
    
    # Configurer la console série (optionnel mais recommandé)
    qm set $CLOUD_INIT_TEMPLATE_ID --serial0 socket --vga serial0
    echo "✓ Console série configurée"
    
    # Activer l'agent QEMU
    qm set $CLOUD_INIT_TEMPLATE_ID --agent enabled=1
    echo "✓ Agent QEMU activé"
    
    # Convertir en template
    qm template $CLOUD_INIT_TEMPLATE_ID
    echo "✓ VM convertie en template"
    
    # Nettoyer
    cd -
    rm -rf "$temp_dir"
    
    echo ""
    echo "✅ Template cloud-init créé avec succès (ID: $CLOUD_INIT_TEMPLATE_ID)"
    echo ""
}

# ========== FONCTION DE SÉLECTION AUTOMATIQUE D'ISO ==========

auto_select_iso() {
    local ISO_STORAGE=$1
    local VM_NAME=$2
    local PREFERRED_ISO=$3
    
    echo "" >&2
    echo "Sélection automatique de l'ISO pour $VM_NAME..." >&2
    
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
        echo "❌ Aucune ISO trouvée dans le stockage $ISO_STORAGE" >&2
        echo "Veuillez télécharger une ISO d'abord." >&2
        exit 1
    fi
    
    # Si une ISO préférée est spécifiée, la chercher
    if [ -n "$PREFERRED_ISO" ]; then
        for iso in "${ISO_LIST[@]}"; do
            if [[ "$iso" == "$PREFERRED_ISO" ]]; then
                echo "✓ ISO trouvée: $iso" >&2
                echo "$iso"
                return 0
            fi
        done
        echo "⚠️  ISO préférée '$PREFERRED_ISO' non trouvée, utilisation de la première disponible" >&2
    fi
    
    # Prendre la première ISO disponible
    echo "✓ ISO sélectionnée automatiquement: ${ISO_LIST[0]}" >&2
    echo "${ISO_LIST[0]}"
    return 0
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
    local USE_CLOUD_INIT=${15}

    echo ""
    echo "=========================================="
    echo "Création de la VM $VMID ($VM_NAME)"
    echo "Type: $OS_TYPE"
    echo "=========================================="
    
    # Vérifier si la VM existe déjà
    if qm status $VMID &>/dev/null; then
        echo "⚠️  Une VM avec l'ID $VMID existe déjà!"
        if [ $AUTO_RECREATE_VMS -eq 1 ]; then
            echo "Mode automatique: suppression et recréation..."
            qm stop $VMID 2>/dev/null || true
            sleep 2
            qm destroy $VMID
            echo "✓ VM supprimée"
        else
            echo "⏭️  Saut de la VM $VMID (AUTO_RECREATE_VMS=0)"
            return 0
        fi
    fi

    # Configuration spécifique selon le type d'OS
    if [[ "$OS_TYPE" == "win11" ]]; then
        # Déterminer le type de Windows
        if [[ "$VM_NAME" == *"CLIENT"* ]] || [[ "$VM_NAME" == "W11"* ]]; then
            echo "Configuration Windows 11 avec UEFI, TPM et Secure Boot..."
        else
            echo "Configuration Windows Server 2022 avec UEFI, TPM et Secure Boot..."
        fi
        
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
        # Extraire la taille numérique (enlever le G de 120G)
        local DISK_SIZE_NUM="${DISK_SIZE%G}"
        if ! qm set $VMID --sata0 $STORAGE:$DISK_SIZE_NUM,ssd=1,format=raw; then
            echo "❌ Erreur lors de l'ajout du disque SATA"
            return 1
        fi
        echo "✓ Disque principal SATA ajouté avec émulation SSD ($DISK_SIZE sur $STORAGE)"
        
        # Monter l'ISO Windows
        qm set $VMID --ide2 $ISO_STORAGE:iso/$ISO_FILE,media=cdrom
        if [[ "$VM_NAME" == *"CLIENT"* ]] || [[ "$VM_NAME" == "W11"* ]]; then
            echo "✓ ISO Windows 11 monté ($ISO_FILE)"
        else
            echo "✓ ISO Windows Server 2022 monté ($ISO_FILE)"
        fi
        
        # Note: Ajouter les drivers VirtIO si disponible
        echo "ℹ️  Note: Pensez à monter l'ISO VirtIO drivers pour l'installation Windows Server"
        echo "   Commande: qm set $VMID --ide0 local:iso/virtio-win.iso,media=cdrom"
        
        # Configurer le boot
        qm set $VMID --boot order=sata0\;ide2
        echo "✓ Ordre de boot configuré (SATA + SSD emulation)"
        
        # Agent QEMU pour Windows (sera disponible après installation de qemu-guest-agent)
        qm set $VMID --agent enabled=1,fstrim_cloned_disks=1
        echo "✓ Agent QEMU configuré (installer qemu-guest-agent dans Windows)"
        
    else
        # Configuration pour Linux
        if [ "$USE_CLOUD_INIT" -eq 1 ]; then
            echo "Configuration Linux avec cloud-init (clonage du template $CLOUD_INIT_TEMPLATE_ID)..."
            
            # Vérifier que le template existe
            if ! qm status $CLOUD_INIT_TEMPLATE_ID &>/dev/null; then
                echo "❌ Erreur: Le template cloud-init $CLOUD_INIT_TEMPLATE_ID n'existe pas!"
                echo "   Créez d'abord un template cloud-init."
                return 1
            fi
            
            # Cloner le template
            qm clone $CLOUD_INIT_TEMPLATE_ID $VMID --name $VM_NAME --full
            echo "✓ VM clonée depuis le template cloud-init"
            
            # Redimensionner le disque si nécessaire
            qm resize $VMID scsi0 $DISK_SIZE
            echo "✓ Disque redimensionné à $DISK_SIZE"
            
            # Configuration CPU et RAM
            qm set $VMID --cores $CORES --memory $MEMORY
            echo "✓ CPU et RAM configurés ($CORES cores, $MEMORY MB)"
            
            # Configuration cloud-init
            qm set $VMID --ciuser "$CLOUD_INIT_USER"
            echo "✓ Utilisateur cloud-init: $CLOUD_INIT_USER"
            
            qm set $VMID --cipassword "$CLOUD_INIT_PASSWORD"
            echo "✓ Mot de passe cloud-init configuré"
            
            # Clé SSH (si fournie)
            if [ -n "$CLOUD_INIT_SSH_KEY" ] && [ -f "$CLOUD_INIT_SSH_KEY" ]; then
                qm set $VMID --sshkeys "$CLOUD_INIT_SSH_KEY"
                echo "✓ Clé SSH configurée"
            fi
            
            # Configuration réseau via cloud-init
            if [ "$IP_ADDRESS" = "dhcp" ] || [ -z "$IP_ADDRESS" ]; then
                qm set $VMID --ipconfig0 ip=dhcp
                echo "✓ Configuration réseau: DHCP"
            else
                qm set $VMID --ipconfig0 ip=$IP_ADDRESS,gw=$GATEWAY
                echo "✓ Configuration réseau: $IP_ADDRESS (gateway: $GATEWAY)"
            fi
            
            # DNS
            if [ -n "$DNS" ]; then
                qm set $VMID --nameserver $DNS
                echo "✓ DNS configuré: $DNS"
            fi
            
            # Agent QEMU
            qm set $VMID --agent enabled=1
            echo "✓ Agent QEMU activé"
            
        else
            echo "Configuration Linux standard avec ISO..."
            
            qm create $VMID \
                --name $VM_NAME \
                --cores $CORES \
                --memory $MEMORY \
                --net0 virtio,bridge=$BRIDGE \
                --ostype l26

            echo "✓ VM Linux de base créée"

            # Ajouter le disque en SATA avec émulation SSD
            # Extraire la taille numérique (enlever le G de 50G)
            local DISK_SIZE_NUM="${DISK_SIZE%G}"
            if ! qm set $VMID --sata0 $STORAGE:$DISK_SIZE_NUM,ssd=1,format=raw; then
                echo "❌ Erreur lors de l'ajout du disque SATA"
                return 1
            fi

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
    fi

    # Configuration réseau statique (si spécifié, uniquement pour cloud-init/Linux)
    if [ -n "$IP_ADDRESS" ] && [ "$USE_CLOUD_INIT" -eq 1 ]; then
        if [ -n "$GATEWAY" ]; then
            qm set $VMID --ipconfig0 ip=$IP_ADDRESS,gw=$GATEWAY
        else
            qm set $VMID --ipconfig0 ip=$IP_ADDRESS
        fi
        echo "✓ Configuration réseau statique: $IP_ADDRESS"
    fi

    # Configuration DNS (si spécifié, uniquement pour cloud-init/Linux)
    if [ -n "$DNS" ] && [ "$USE_CLOUD_INIT" -eq 1 ]; then
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
        if [[ "$VM_NAME" == *"CLIENT"* ]] || [[ "$VM_NAME" == "W11"* ]]; then
            echo "   Type: Windows 11 (UEFI + TPM 2.0 + Secure Boot)"
        else
            echo "   Type: Windows Server 2022 Desktop Experience (UEFI + TPM 2.0 + Secure Boot)"
        fi
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

# Créer le template cloud-init si nécessaire
if [ "$VM3_USE_CLOUD_INIT" -eq 1 ] || [ "$VM4_USE_CLOUD_INIT" -eq 1 ]; then
    create_cloud_init_template
fi

# Sélectionner l'ISO pour chaque VM
echo ""
echo "=========================================="
echo "Sélection automatique des ISOs"
echo "=========================================="

VM1_ISO_FILE=$(auto_select_iso "$VM1_ISO_STORAGE" "$VM1_NAME" "$VM1_ISO_NAME")
echo "✓ ISO sélectionnée pour VM1: $VM1_ISO_FILE"

VM2_ISO_FILE=$(auto_select_iso "$VM2_ISO_STORAGE" "$VM2_NAME" "$VM2_ISO_NAME")
echo "✓ ISO sélectionnée pour VM2: $VM2_ISO_FILE"

# VM3 utilise cloud-init, pas besoin d'ISO
if [ "$VM3_USE_CLOUD_INIT" -eq 1 ]; then
    VM3_ISO_FILE=""
    echo "✓ VM3 utilisera cloud-init (pas d'ISO nécessaire)"
else
    VM3_ISO_FILE=$(auto_select_iso "$VM3_ISO_STORAGE" "$VM3_NAME" "")
    echo "✓ ISO sélectionnée pour VM3: $VM3_ISO_FILE"
fi

# VM4 utilise cloud-init, pas besoin d'ISO
if [ "$VM4_USE_CLOUD_INIT" -eq 1 ]; then
    VM4_ISO_FILE=""
    echo "✓ VM4 utilisera cloud-init (pas d'ISO nécessaire)"
else
    VM4_ISO_FILE=$(auto_select_iso "$VM4_ISO_STORAGE" "$VM4_NAME" "")
    echo "✓ ISO sélectionnée pour VM4: $VM4_ISO_FILE"
fi

VM5_ISO_FILE=$(auto_select_iso "$VM5_ISO_STORAGE" "$VM5_NAME" "$VM5_ISO_NAME")
echo "✓ ISO sélectionnée pour VM5: $VM5_ISO_FILE"

# Créer les cinq VMs
create_vm "$VM1_ID" "$VM1_NAME" "$VM1_CORES" "$VM1_MEMORY" "$VM1_DISK_SIZE" \
    "$VM1_STORAGE" "$VM1_BRIDGE" "$VM1_IP" "$VM1_GATEWAY" "$VM1_DNS" \
    "$VM1_ISO_STORAGE" "$VM1_ISO_FILE" "$VM1_START_ON_BOOT" "$VM1_OS_TYPE" "0"

create_vm "$VM2_ID" "$VM2_NAME" "$VM2_CORES" "$VM2_MEMORY" "$VM2_DISK_SIZE" \
    "$VM2_STORAGE" "$VM2_BRIDGE" "$VM2_IP" "$VM2_GATEWAY" "$VM2_DNS" \
    "$VM2_ISO_STORAGE" "$VM2_ISO_FILE" "$VM2_START_ON_BOOT" "$VM2_OS_TYPE" "0"

create_vm "$VM3_ID" "$VM3_NAME" "$VM3_CORES" "$VM3_MEMORY" "$VM3_DISK_SIZE" \
    "$VM3_STORAGE" "$VM3_BRIDGE" "$VM3_IP" "$VM3_GATEWAY" "$VM3_DNS" \
    "$VM3_ISO_STORAGE" "$VM3_ISO_FILE" "$VM3_START_ON_BOOT" "$VM3_OS_TYPE" "$VM3_USE_CLOUD_INIT"

create_vm "$VM4_ID" "$VM4_NAME" "$VM4_CORES" "$VM4_MEMORY" "$VM4_DISK_SIZE" \
    "$VM4_STORAGE" "$VM4_BRIDGE" "$VM4_IP" "$VM4_GATEWAY" "$VM4_DNS" \
    "$VM4_ISO_STORAGE" "$VM4_ISO_FILE" "$VM4_START_ON_BOOT" "$VM4_OS_TYPE" "$VM4_USE_CLOUD_INIT"

create_vm "$VM5_ID" "$VM5_NAME" "$VM5_CORES" "$VM5_MEMORY" "$VM5_DISK_SIZE" \
    "$VM5_STORAGE" "$VM5_BRIDGE" "$VM5_IP" "$VM5_GATEWAY" "$VM5_DNS" \
    "$VM5_ISO_STORAGE" "$VM5_ISO_FILE" "$VM5_START_ON_BOOT" "$VM5_OS_TYPE" "0"

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
