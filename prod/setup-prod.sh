#!/usr/bin/env bash
# Réinstallation du serveur de production Truitteur (Debian 12).
# Usage : depuis le dossier prod/ du dépôt, copier sur la VM puis : sudo bash setup-prod.sh
# Le script est complété à chaque étape du projet.
set -euo pipefail
cd "$(dirname "$0")"

echo "[1/5] Mise à jour du système"
apt update && apt full-upgrade -y

echo "[2/5] Durcissement SSH"
install -m 644 ssh/00-hardening.conf /etc/ssh/sshd_config.d/00-hardening.conf
sshd -t
systemctl reload ssh

echo "[3/5] fail2ban"
apt install -y fail2ban python3-systemd
install -m 644 fail2ban/jail.local /etc/fail2ban/jail.local
systemctl enable --now fail2ban
systemctl restart fail2ban

echo "[4/5] Mises à jour de sécurité automatiques"
apt install -y unattended-upgrades apt-listchanges
install -m 644 apt/20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades

echo "[5/5] Pare-feu iptables (tout en DROP, entrée et sortie)"
apt install -y locales
sed -i 's/^# *fr_FR.UTF-8 UTF-8/fr_FR.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
echo "iptables-persistent iptables-persistent/autosave_v4 boolean false" | debconf-set-selections
echo "iptables-persistent iptables-persistent/autosave_v6 boolean false" | debconf-set-selections
apt install -y iptables iptables-persistent
install -m 640 iptables/rules.v4 /etc/iptables/rules.v4
install -m 640 iptables/rules.v6 /etc/iptables/rules.v6
# Filet de sécurité : annulation automatique sans confirmation sous 120 s
iptables-apply -t 120 /etc/iptables/rules.v4
ip6tables-restore < /etc/iptables/rules.v6
systemctl enable netfilter-persistent
systemctl restart fail2ban

echo "Terminé. Tester une NOUVELLE connexion SSH dans un autre terminal avant de fermer celui-ci."
