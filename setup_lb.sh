#!/bin/bash

echo "[INFO] Configuration du load balancer avec Nginx"

# Mise à jour et installation
apt-get update
apt-get install -y nginx

# Configuration Nginx pour le load balancing
cat > /etc/nginx/sites-available/default << 'EOL'
upstream backend {
    server 192.168.56.11 max_fails=3 fail_timeout=10s; # web1
    server 192.168.56.12 max_fails=3 fail_timeout=10s; # web2
}

server {
    listen 80;
    server_name lb;

    location / {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        index index.php;
    }
}
EOL

# Redémarrage de nginx
systemctl restart nginx

# Installation de Node Exporter
echo "[INFO] Installation de Node Exporter..."
useradd --no-create-home --shell /bin/false node_exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.4.0/node_exporter-1.4.0.linux-amd64.tar.gz
tar -xvf node_exporter-1.4.0.linux-amd64.tar.gz
cp node_exporter-1.4.0.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-1.4.0.linux-amd64*

# Service systemd pour Node Exporter
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

# Démarrage de node_exporter
systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter

echo "[INFO] Load balancer configuré avec succès"
