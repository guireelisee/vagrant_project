#!/bin/bash

# Script pour installer Prometheus et Grafana pour la surveillance

echo "[INFO] Configuration du serveur de monitoring avec Prometheus et Grafana"

# Mise à jour des dépôts
apt-get update

# Installation des dépendances
apt-get install -y apt-transport-https software-properties-common wget curl net-tools

# Installation de Prometheus
echo "[INFO] Installation de Prometheus..."
useradd --no-create-home --shell /bin/false prometheus
mkdir -p /etc/prometheus /var/lib/prometheus

wget https://github.com/prometheus/prometheus/releases/download/v2.40.0/prometheus-2.40.0.linux-amd64.tar.gz
tar -xvf prometheus-2.40.0.linux-amd64.tar.gz
cd prometheus-2.40.0.linux-amd64
cp prometheus promtool /usr/local/bin/
cp -r consoles/ console_libraries/ /etc/prometheus/
cd ..
rm -rf prometheus-2.40.0.linux-amd64 prometheus-2.40.0.linux-amd64.tar.gz

# Configuration de Prometheus
cat > /etc/prometheus/prometheus.yml << 'EOL'
global:
  scrape_interval: 15s

scrape_configs:          
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
        labels:
          instance: 'monitoring-vm'

      - targets: ['192.168.56.10:9100']
        labels:
          instance: 'lb-vm'

      - targets: ['192.168.56.11:9100']
        labels:
          instance: 'web1-vm'

      - targets: ['192.168.56.12:9100']
        labels:
          instance: 'web2-vm'

      - targets: ['192.168.56.20:9100']
        labels:
          instance: 'db-master-vm'
          
      - targets: ['192.168.56.21:9100']
        labels:
          instance: 'db-slave-vm'

  - job_name: 'mysql_exporter'
    static_configs:
      - targets: ['192.168.56.20:9104']
        labels:
          instance: 'db-master-vm'
      - targets: ['192.168.56.21:9104']
        labels:
          instance: 'db-slave-vm'
EOL

# Création du service Prometheus
cat > /etc/systemd/system/prometheus.service << 'EOL'
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries \
    --web.listen-address=0.0.0.0:9090

[Install]
WantedBy=multi-user.target
EOL

# Permissions pour les répertoires Prometheus
chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
chmod -R 775 /etc/prometheus /var/lib/prometheus

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

# Installation de Grafana
echo "[INFO] Installation de Grafana..."
# Méthode moderne pour ajouter la clé GPG
wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key
echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list
apt-get update
apt-get install -y grafana

# Configuration de Grafana pour écouter sur toutes les interfaces
echo "[INFO] Configuration de Grafana pour écouter sur toutes les interfaces..."
sed -i 's/^;http_addr = .*/http_addr = 0.0.0.0/' /etc/grafana/grafana.ini

# Démarrer et activer les services
systemctl daemon-reload
systemctl restart prometheus
systemctl enable prometheus
systemctl restart node_exporter
systemctl enable node_exporter
systemctl restart grafana-server
systemctl enable grafana-server

# Vérification des services
echo "[INFO] Vérification des services..."
systemctl status prometheus --no-pager
systemctl status node_exporter --no-pager
systemctl status grafana-server --no-pager

# Script pour configurer des tableaux de bord Grafana automatiquement
# Attendre que Grafana soit prêt avec timeout
echo "Attente du démarrage de Grafana..."
TIMEOUT=60
ELAPSED=0

until curl -s http://localhost:3000/api/health | grep -q "ok"; do
  if [ $ELAPSED -ge $TIMEOUT ]; then
    echo "Timeout atteint en attendant Grafana!"
    echo "État de Grafana:"
    systemctl status grafana-server --no-pager
    echo "Ports ouverts:"
    netstat -tulpn | grep 3000
    exit 1
  fi
  sleep 5
  ELAPSED=$((ELAPSED+5))
  echo "Toujours en attente... ($ELAPSED/$TIMEOUT secondes)"
done

echo "Grafana est prêt! Ajout de la source de données Prometheus..."

# Ajouter la source de données Prometheus
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d '{
    "name":"Prometheus",
    "type":"prometheus",
    "url":"http://localhost:9090",
    "access":"proxy",
    "basicAuth":false,
    "isDefault":true
}' http://admin:admin@localhost:3000/api/datasources)

echo "Réponse de l'API Grafana: $RESPONSE"

echo "Ajout des dashboards depuis grafana.com..."

# Fonction pour importer un dashboard depuis grafana.com
import_dashboard() {
  local DASHBOARD_ID=$1
  local DASHBOARD_NAME=$2

  echo "Import du dashboard $DASHBOARD_NAME (ID $DASHBOARD_ID)..."
  
  # Télécharger d'abord le dashboard dans un fichier temporaire
  DASHBOARD_FILE="/tmp/dashboard_${DASHBOARD_ID}.json"
  curl -s -o "$DASHBOARD_FILE" "https://grafana.com/api/dashboards/${DASHBOARD_ID}/revisions/latest/download"
  
  if [ ! -s "$DASHBOARD_FILE" ]; then
    echo "Erreur: Impossible de télécharger le dashboard $DASHBOARD_ID"
    return 1
  fi
  
  # Créer le fichier de configuration pour l'importation
  IMPORT_FILE="/tmp/import_${DASHBOARD_ID}.json"
  cat > "$IMPORT_FILE" << EOF
{
  "dashboard": $(cat "$DASHBOARD_FILE"),
  "overwrite": true,
  "inputs": [
    {
      "name": "DS_PROMETHEUS",
      "type": "datasource",
      "pluginId": "prometheus",
      "value": "Prometheus"
    }
  ]
}
EOF

  # Importer le dashboard avec le fichier préparé
  RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    --data @"$IMPORT_FILE" \
    http://admin:admin@localhost:3000/api/dashboards/import)

  echo "Réponse API Grafana pour $DASHBOARD_NAME: $RESPONSE"
  
  # Nettoyage des fichiers temporaires
  rm -f "$DASHBOARD_FILE" "$IMPORT_FILE"
}

# Importer les dashboards
import_dashboard 1860 "Node Exporter Full"
import_dashboard 14031 "MySQL Dashboard"

echo "Configuration de Grafana terminée"

echo "[INFO] Serveur de monitoring configuré avec succès"
echo "[INFO] Grafana est accessible à l'adresse: http://192.168.56.30:3000 (admin/admin)"
echo "[INFO] Prometheus est accessible à l'adresse: http://192.168.56.30:9090"