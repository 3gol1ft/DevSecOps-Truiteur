# DevSecOps – Truitteur

Projet de l'unité CYB_4201A (ESIEE Paris) : sécuriser toute la chaîne de développement de **Truitteur**, une application Java 17 / Spring Boot à exposer sur le web.

Ce README sert de **journal de bord** : chaque étape réalisée y est décrite (ce qu'on a fait, pourquoi, les fichiers modifiés, les problèmes rencontrés). Il sert de base à la rédaction du rapport final (rendu prévu le 21/01, à confirmer).

## Équipe : Les 4 vulnérabilités

| Membre | Rôle principal |
|--------|----------------|
| Lucas (capitaine) | Coordination, rapport, schémas, appui Sec |
| Lucien | Ops – serveurs de production et CI/CD (SSH, iptables, installation des services) |
| Ayoub | Dev – configuration Jenkins / Nexus / SonarQube et pipeline |
| Steven | Sec – analyse SonarQube, tests OWASP, rapport de failles |

Tout le monde doit comprendre l'ensemble du projet (QCM final et rapport commun) : chaque étape est expliquée dans le journal ci-dessous.

## Méthode de travail

- Toujours faire `git pull` avant de modifier un fichier, puis un commit par étape avec un message clair.
- Chaque étape terminée est documentée dans le **Journal de bord** : objectif, commandes, fichiers modifiés, problèmes rencontrés, captures.
- Les fichiers de configuration finaux sont rangés dans `prod/`, `cicd/` ou `pipeline/` : ils permettent de réinstaller un serveur rapidement si quelque chose casse.
- Sauvegardes : volumes de démarrage sauvegardés côté Oracle Cloud à chaque étape majeure, en plus de ce dépôt.

## Architecture

| VM | Rôle | Services |
|----|------|----------|
| `prod` | Production | SSH, iptables, JRE 17, PostgreSQL 15, nginx (reverse proxy), service systemd |
| `cicd` | Intégration / livraison continue | SSH, iptables, Jenkins, SonarQube, Nexus 3, Maven, JDK 17, git, nginx (reverse proxy) |

Hébergement : Oracle Cloud (Always Free, Ampere A1), Debian 12.

_Schéma d'architecture à ajouter._

## Organisation du dépôt

| Dossier | Contenu |
|---------|---------|
| `prod/` | Fichiers de configuration du serveur de production (sshd, iptables, nginx, systemd…) |
| `cicd/` | Fichiers de configuration du serveur CI/CD (Jenkins, SonarQube, Nexus, nginx…) |
| `pipeline/` | Jenkinsfile et scripts de déploiement |
| `sec/` | Rapports d'analyse, liste et priorisation des failles |
| `captures/` | Captures d'écran pour le rapport (nommées `NN-etape-description.png`) |

⚠️ Aucun secret (clé privée, mot de passe, token) ne doit être commité.

## Tableau d'avancement

| Étape | Statut | Responsable |
|-------|--------|-------------|
| SSH | À faire | Lucien |
| Iptables | À faire | Lucien |
| Prod | À faire | Lucien |
| Serveur CI/CD | À faire | Lucien / Ayoub |
| Jenkins | À faire | Ayoub |
| Sonar | À faire | Ayoub |
| Nexus | À faire | Ayoub |
| Pipeline | À faire | Ayoub |
| Analyse | À faire | Steven / Lucas |
| Déploiement | À faire | Tous |

Statuts possibles : À faire · Commencé · En cours · À faire vérifier · Validé · Terminé

## Journal de bord

_Les étapes seront ajoutées ici au fur et à mesure._

## Sources

_Format IEEE, à compléter au fil du projet._
