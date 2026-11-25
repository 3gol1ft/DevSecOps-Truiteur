#!/usr/bin/env bash
# Recrée la VM de production sur Azure for Students (à lancer dans Azure Cloud Shell).
# Contexte : sur les abonnements étudiants, seules les familles v7 sont autorisées
# et leur quota standard est à 0 -> on passe par le quota Spot (3 cœurs).
set -euo pipefail

RG=rg-truitteur-francecentral
LOC=francecentral
VM=truitteur-prod
SIZE=Standard_D2as_v7          # 2 vCPU AMD, 8 Go de RAM
USER_ADMIN=lucien
PUBKEY='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM5ouWd7FYS9/iMDACPU47/CCxhwVInLbjtQYjpXlP3L lucien-truitteur'

az group create -n "$RG" -l "$LOC" -o none

az vm create -g "$RG" -n "$VM" -l "$LOC" \
  --image Debian:debian-12:12-gen2:latest \
  --size "$SIZE" \
  --priority Spot --eviction-policy Deallocate --max-price -1 \
  --admin-username "$USER_ADMIN" --ssh-key-values "$PUBKEY" \
  --os-disk-size-gb 64 --storage-sku StandardSSD_LRS \
  --nsg-rule SSH -o table

# Arrêt automatique chaque soir à 23h (heure de Paris = 22h UTC)
az vm auto-shutdown -g "$RG" -n "$VM" --time 2200 --email lucien.popa@edu.esiee.fr -o none
