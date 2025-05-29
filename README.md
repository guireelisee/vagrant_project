# Déploiement d’une Infrastructure Multi-Machines avec Vagrant et Bash

Ce projet met en place une infrastructure complète pour une application web simple comprenant 7 machines virtuelles, chacune avec un rôle spécifique dans l'architecture.

## Architecture

L'infrastructure se compose des machines virtuelles suivantes, toutes configurées dans un réseau privé `192.168.56.0/24` :

1. **lb** (192.168.56.10) : Load Balancer qui équilibre le trafic entre web1 et web2
2. **web1** (192.168.56.11) : Serveur web Apache qui sert les pages HTML
3. **web2** (192.168.56.12) : Serveur web Apache qui sert les pages HTML
4. **db-master** (192.168.56.20) : Base de données MySQL maître qui contient les données et envoie les mises à jour à db-slave
5. **db-slave** (192.168.56.21) : Base de données MySQL esclave qui reçoit les mises à jour de db-master
6. **monitoring** (192.168.56.30) : Serveur de supervision avec Prometheus et Grafana pour surveiller l'infrastructure
7. **client** (192.168.56.100) : Machine cliente utilisée pour tester la connectivité

## Installation

1. Clonez ce dépôt sur votre machine locale
2. Ouvrez un terminal et naviguez jusqu'au répertoire du projet
3. Lancez la création des machines virtuelles :

```bash
vagrant up
```

Cette commande va créer et configurer toutes les machines virtuelles selon les spécifications du `Vagrantfile`. Le processus peut prendre plusieurs minutes en fonction de votre connexion internet et des ressources de votre ordinateur.

## Utilisation

### Accès aux services

- **Application Web** : http://192.168.56.10 (Load Balancer)
- **Serveurs Web individuels** : 
  - http://192.168.56.11 (web1)
  - http://192.168.56.12 (web2)
- **Monitoring** :
  - Prometheus : http://192.168.56.30:9090
  - Grafana : http://192.168.56.30:3000 (utilisateur: admin, mot de passe: admin)

### Connexion SSH aux machines

Pour vous connecter à l'une des machines virtuelles :

```bash
vagrant ssh [nom-de-la-machine]
```

Exemple : `vagrant ssh client` pour se connecter au client.

## Détails techniques

### Load Balancer (lb)

- **Technologie** : Nginx
- **Stratégie** : Round-robin entre web1 et web2

### Serveurs Web (web1, web2)

- **Technologie** : Apache avec PHP
- **Contenu** : Page d'accueil HTML statique et script PHP pour tester la connexion à la base de données

### Base de Données (db-master, db-slave)

- **Technologie** : MySQL
- **Configuration** : Réplication maître-esclave
- **Base de données** : `webappdb` avec une table de démonstration `demo_table`
- **Utilisateurs : Mot de passe** :
  - `root : rootpassword` (administrateur)
  - `webuser : webpass` (utilisé par les serveurs web)
  - `replicator : replpass` (utilisé pour la réplication)

### Monitoring (monitoring)

- **Technologies** :
  - Prometheus pour la collecte des métriques
  - Node Exporter pour la surveillance des serveurs
  - MySQL Exporter pour la surveillance des bases de données MySQL
  - Grafana pour la visualisation des données

## Résolution des problèmes courants

- **Problèmes de connexion** : Assurez-vous que toutes les VMs sont démarrées et que les services sont actifs
- **Problèmes de mémoire** : Si VirtualBox signale des problèmes de mémoire, réduisez la RAM allouée dans le Vagrantfile

## Arrêt et suppression des machines virtuelles

- Pour mettre en pause toutes les machines :
  ```bash
  vagrant suspend
  ```

- Pour arrêter toutes les machines :
  ```bash
  vagrant halt
  ```

- Pour supprimer toutes les machines :
  ```bash
  vagrant destroy
  ```