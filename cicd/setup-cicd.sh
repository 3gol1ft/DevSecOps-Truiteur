#!/usr/bin/env bash
# Réinstallation du serveur CI/CD Truitteur (Debian 12).
# Usage : depuis le dossier cicd/ du dépôt, copier sur la VM puis : sudo bash setup-cicd.sh
# Le script est complété à chaque étape du projet.
set -euo pipefail
cd "$(dirname "$0")"

echo "[1/4] Mise à jour du système"
apt update && apt full-upgrade -y

echo "[2/4] Durcissement SSH"
install -m 644 ssh/00-hardening.conf /etc/ssh/sshd_config.d/00-hardening.conf
sshd -t
systemctl reload ssh

echo "[3/4] fail2ban"
apt install -y fail2ban python3-systemd
install -m 644 fail2ban/jail.local /etc/fail2ban/jail.local
systemctl enable --now fail2ban
systemctl restart fail2ban

echo "[4/4] Mises à jour de sécurité automatiques"
apt install -y unattended-upgrades apt-listchanges
install -m 644 apt/20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades

echo "Étape SSH terminée. Tester la connexion dans un AUTRE terminal avant de fermer celui-ci."
