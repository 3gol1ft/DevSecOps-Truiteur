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

### Étape 0 – Choix de l'hébergement et du système

**Statut : choix faits, création du compte Oracle et des VM à faire.**

#### Qu'est-ce qu'Oracle Cloud ?
Oracle Cloud Infrastructure (OCI) est le cloud public d'Oracle. Il fonctionne en *IaaS* (Infrastructure as a Service) : on loue des machines virtuelles, du stockage et du réseau, et on gère nous-mêmes le système et les logiciels installés dessus. Les briques OCI que nous utilisons :
- **Compute** : les machines virtuelles (instances) ;
- **VCN** (Virtual Cloud Network) : le réseau privé virtuel dans lequel les VM sont placées ;
- **Security Lists** : un pare-feu géré par Oracle, en amont des VM. Il s'ajoute au pare-feu iptables de chaque VM (défense en profondeur) ;
- **Boot volume backups** : les sauvegardes des disques des VM.

#### Pourquoi Oracle Cloud ?
Le professeur nous a laissé libres du choix de la plateforme. Nous avons comparé les offres gratuites accessibles à des étudiants :

| Plateforme | Offre | Limites pour notre projet |
|------------|-------|---------------------------|
| **Oracle Cloud (Always Free)** | 4 OCPU ARM + 24 Go de RAM + 200 Go de disque, **gratuit sans limite de durée** [1] | Carte bancaire demandée pour la vérification d'identité (non débitée) ; processeurs ARM |
| Azure for Students | 100 $ de crédits sur 12 mois, sans carte [3] | Crédits épuisés en quelques mois avec 2 VM de 8 Go ou plus |
| AWS / Google Cloud | Offres gratuites limitées à de petites VM (≈1 Go de RAM) | Insuffisant pour Jenkins + SonarQube + Nexus |
| DigitalOcean (GitHub Student Pack) | Offre étudiante arrêtée en juillet 2026 | Plus disponible |

Oracle est la seule offre **permanente** et assez grande pour nos deux serveurs : les deux VM tiennent dans un seul compte (8 Go + 16 Go = 24 Go de RAM). La VM CI/CD reçoit plus de mémoire parce que SonarQube et Nexus sont gourmands.

Points de vigilance :
- **Architecture ARM** (Ampere A1) : il faudra vérifier que SonarQube et Nexus 3 fonctionnent bien sur ARM64 avant de les installer ;
- **Capacité** : Oracle peut refuser de créer une VM ARM si la région est saturée (« Out of capacity ») ;
- **Pas de SLA** : l'offre gratuite n'a aucune garantie de disponibilité, d'où l'intérêt des sauvegardes.

#### Pourquoi Debian 12 ?
- **Les versions demandées par le sujet sont dans les dépôts officiels** : Debian 12 fournit directement OpenJDK 17 et PostgreSQL 15. Debian 13 fournit des versions plus récentes (Java 21, PostgreSQL 17) et nous obligerait à ajouter des dépôts tiers, ce qui élargit la chaîne de confiance ;
- **Toujours maintenue** : le support standard de Debian 12 s'est terminé en juillet 2026, mais elle reçoit les correctifs de sécurité de l'équipe LTS jusqu'au 30 juin 2028, y compris sur ARM64 [2]. Cela couvre largement la durée du projet ;
- **Distribution stable et répandue** sur les serveurs, très bien documentée.

Debian n'étant pas proposée dans les images de base d'Oracle, nous importons l'image officielle *Debian 12 genericcloud arm64* comme image personnalisée.

#### Pourquoi sans interface graphique ?
- **Surface d'attaque réduite** : moins de paquets installés, donc moins de failles potentielles et moins de mises à jour ;
- **Moins de ressources consommées**, laissées aux services du projet ;
- **Administration uniquement par SSH**, ce qui est la norme pour un serveur et permet de tout scripter (réinstallation rapide).

## Sources

[1] Oracle, « Oracle Cloud Infrastructure Free Tier », *Oracle Cloud Infrastructure Documentation*. [En ligne]. Disponible : https://docs.oracle.com/iaas/Content/FreeTier/freetier.htm

[2] Debian, « Debian "bookworm" Release Information ». [En ligne]. Disponible : https://www.debian.org/releases/bookworm/

[3] Microsoft, « Azure for Students ». [En ligne]. Disponible : https://azure.microsoft.com/en-us/pricing/offers/ms-azr-0170p/
