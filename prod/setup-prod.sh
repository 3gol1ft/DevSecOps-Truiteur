#!/usr/bin/env bash
# Réinstallation du serveur de production Truitteur (Debian 12).
# Usage : depuis le dossier prod/ du dépôt, copier sur la VM puis : sudo bash setup-prod.sh
# Le script est complété à chaque étape du projet.
set -euo pipefail
cd "$(dirname "$0")"

echo "[1/6] Mise à jour du système"
apt update && apt full-upgrade -y

echo "[2/6] Durcissement SSH"
install -m 644 ssh/00-hardening.conf /etc/ssh/sshd_config.d/00-hardening.conf
sshd -t
systemctl reload ssh

echo "[3/6] fail2ban"
apt install -y fail2ban python3-systemd
install -m 644 fail2ban/jail.local /etc/fail2ban/jail.local
systemctl enable --now fail2ban
systemctl restart fail2ban

echo "[4/6] Mises à jour de sécurité automatiques"
apt install -y unattended-upgrades apt-listchanges
install -m 644 apt/20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades

echo "[5/6] Pare-feu iptables (tout en DROP, entrée et sortie)"
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

echo "[6/6] Services de production : Java 17, PostgreSQL 15, nginx"
apt install -y openjdk-17-jre-headless postgresql-15 nginx

# Compte système de l'application (sans shell)
id truitteur >/dev/null 2>&1 || useradd --system --home-dir /opt/truitteur --create-home --shell /usr/sbin/nologin truitteur

# Base de données et secret (créés seulement s'ils n'existent pas)
if [ ! -f /etc/truitteur/truitteur.env ]; then
  DBPASS=$(openssl rand -base64 24)
  sudo -u postgres psql -c "CREATE ROLE truitteur LOGIN PASSWORD '$DBPASS';"
  sudo -u postgres psql -c "CREATE DATABASE truitteur OWNER truitteur;"
  sudo -u postgres psql -c "REVOKE ALL ON DATABASE truitteur FROM PUBLIC;"
  install -d -m 750 -o root -g truitteur /etc/truitteur
  printf 'SPRING_DATASOURCE_URL=jdbc:postgresql://127.0.0.1:5432/truitteur\nSPRING_DATASOURCE_USERNAME=truitteur\nSPRING_DATASOURCE_PASSWORD=%s\n' "$DBPASS" > /etc/truitteur/truitteur.env
  chown root:truitteur /etc/truitteur/truitteur.env && chmod 640 /etc/truitteur/truitteur.env
  unset DBPASS
fi

# nginx en reverse proxy
install -m 644 nginx/00-securite.conf /etc/nginx/conf.d/00-securite.conf
install -m 644 nginx/truitteur /etc/nginx/sites-available/truitteur
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/truitteur /etc/nginx/sites-enabled/truitteur
nginx -t && systemctl reload nginx

echo "Terminé. Tester une NOUVELLE connexion SSH dans un autre terminal avant de fermer celui-ci."
