#!/bin/bash

# Script pour configurer MySQL comme serveur esclave

echo "[INFO] Configuration du serveur de base de données esclave avec MySQL"

# Définition de la variable pour éviter les prompts lors de l'installation
export DEBIAN_FRONTEND=noninteractive

# Mise à jour des dépôts et installation de MySQL
apt-get update
apt-get install -y mysql-server

# Sécurisation de l'installation MySQL
mysql --execute="ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'rootpassword';"
mysql --user=root --password=rootpassword --execute="DELETE FROM mysql.user WHERE User='';"
mysql --user=root --password=rootpassword --execute="DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql --user=root --password=rootpassword --execute="DROP DATABASE IF EXISTS test;"
mysql --user=root --password=rootpassword --execute="DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql --user=root --password=rootpassword --execute="FLUSH PRIVILEGES;"

# Configuration de MySQL pour la réplication maître-esclave
cat > /etc/mysql/mysql.conf.d/mysqld-replication.cnf << 'EOL'
[mysqld]
server-id = 2
log_bin = /var/log/mysql/mysql-bin.log
binlog_format = ROW
replicate_do_db = webappdb
EOL

# Redémarrage de MySQL pour appliquer les changements
systemctl restart mysql

# Création de la base de données pour la réplication
mysql --user=root --password=rootpassword --execute="CREATE DATABASE IF NOT EXISTS webappdb;"

# Autoriser les connexions à MySQL depuis l'extérieur
sed -i 's/bind-address.*=.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

# Redémarrage de MySQL
systemctl restart mysql

# Importer le fichier de configuration pour l'esclave
mv /vagrant/.vagrant/replication_info.sql /home/vagrant/
mv /vagrant/.vagrant/full_database_dump.sql /home/vagrant/

# Vérifier si le fichier existe
if [ -f /home/vagrant/replication_info.sql ]; then
    echo "[INFO] Configuration de la réplication en cours..."
    # Configuration de la réplication
    REPLICATION_CMD=$(cat /home/vagrant/replication_info.sql)
    mysql --user=root --password=rootpassword --execute="STOP SLAVE;"
    mysql --user=root --password=rootpassword --execute="$REPLICATION_CMD"
    mysql --user=root --password=rootpassword --execute="START SLAVE;"
    
    # Vérification du statut de la réplication
    SLAVE_STATUS=$(mysql --user=root --password=rootpassword --execute="SHOW SLAVE STATUS\G")
    echo "$SLAVE_STATUS"
    
    # Charger la base dumpée
    mysql --user=root --password=rootpassword < /home/vagrant/full_database_dump.sql

    echo "[INFO] Configuration de la réplication terminée"
else
    echo "[ERREUR] Fichier de configuration de réplication non trouvé"
    echo "Veuillez exécuter manuellement la commande suivante après l'initialisation du maître:"
    echo "mysql -u root -p -e \"CHANGE MASTER TO MASTER_HOST='192.168.56.20', MASTER_USER='replicator', MASTER_PASSWORD='replpass', MASTER_LOG_FILE='mysql-bin.XXXX', MASTER_LOG_POS=XXX; START SLAVE;\""
fi

# Installation de Node Exporter pour la surveillance des serveurs
echo "[INFO] Installation de Node Exporter..."
useradd --no-create-home --shell /bin/false node_exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.4.0/node_exporter-1.4.0.linux-amd64.tar.gz
tar -xvf node_exporter-1.4.0.linux-amd64.tar.gz
cp node_exporter-1.4.0.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-1.4.0.linux-amd64 node_exporter-1.4.0.linux-amd64.tar.gz

# Création du service Node Exporter
cat > /etc/systemd/system/node_exporter.service << 'EOL'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOL

# Installation de MySQL Exporter
echo "Installation de MySQL Exporter..."
useradd --no-create-home --shell /bin/false mysqld_exporter

MYSQL_EXPORTER_VERSION="0.14.0"
wget -q https://github.com/prometheus/mysqld_exporter/releases/download/v${MYSQL_EXPORTER_VERSION}/mysqld_exporter-${MYSQL_EXPORTER_VERSION}.linux-amd64.tar.gz
tar xfz mysqld_exporter-${MYSQL_EXPORTER_VERSION}.linux-amd64.tar.gz

cp mysqld_exporter-${MYSQL_EXPORTER_VERSION}.linux-amd64/mysqld_exporter /usr/local/bin/
rm -rf mysqld_exporter-${MYSQL_EXPORTER_VERSION}.linux-amd64*

# Création de la configuration du MySQL Exporter
cat > /etc/.mysqld_exporter.cnf <<EOF
[client]
user=root
password=rootpassword
host=localhost
EOF

chmod 600 /etc/.mysqld_exporter.cnf
chown mysqld_exporter:mysqld_exporter /etc/.mysqld_exporter.cnf

# Service MySQL Exporter
cat > /etc/systemd/system/mysqld_exporter.service <<EOF
[Unit]
Description=MySQL Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=mysqld_exporter
Group=mysqld_exporter
Type=simple
ExecStart=/usr/local/bin/mysqld_exporter --config.my-cnf=/etc/.mysqld_exporter.cnf

[Install]
WantedBy=multi-user.target
EOF

# Démarrer et activer les services
systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter
systemctl start mysqld_exporter
systemctl enable mysqld_exporter

echo "[INFO] Serveur de base de données esclave configuré avec succès"
