#!/bin/bash

# Script pour configurer Apache et afficher un message d'accueil

echo "[INFO] Configuration du serveur web avec Apache"

# Mise à jour des dépôts et installation d'Apache
apt-get update
apt-get install -y apache2 php libapache2-mod-php php-mysql

# Suppression du fichier index.html par défaut
rm -f /var/www/html/index.html

# Création d'une page d'accueil personnalisée
HOSTNAME=$(hostname)
# Récupération de l'adresse IP
SERVER_IP=$(hostname -I | awk '{print $1}')

# Création d'une page d'accueil avec formulaire
cat > /var/www/html/index.php << 'EOL'
<?php
$hostname = gethostname();
$server_ip = $_SERVER['SERVER_ADDR'];

# Submit

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $nom = isset($_POST["nom"]) ? $_POST["nom"] : "";
    $message = isset($_POST["message"]) ? $_POST["message"] : "";
    
    // Validation simple
    if (empty($nom) || empty($message)) {
        $error = "Tous les champs sont obligatoires";
    } else {
        try {
            // Connexion à la base de données
            $conn = new mysqli('192.168.56.20', 'webuser', 'webpass', 'webappdb');
            
            if ($conn->connect_error) {
                throw new Exception("La connexion a échoué: " . $conn->connect_error);
            }
            
            // Insertion des données
            $stmt = $conn->prepare("INSERT INTO messages (nom, message, serveur) VALUES (?, ?, ?)");
            $stmt->bind_param("sss", $nom, $message, $hostname);
            
            if ($stmt->execute()) {
                $success = "Message enregistré avec succès!";
            } else {
                $error = "Erreur d'enregistrement: " . $stmt->error;
            }
            
            $stmt->close();
            $conn->close();
            
        } catch (Exception $e) {
            $error = "Erreur de connexion à la base de données: " . $e->getMessage();
        }
    }
}

?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <title>Bienvenue sur <?php echo $hostname; ?></title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        :root {
            --primary-color: #2c3e50;
            --accent-color: #3498db;
            --light-bg: #f5f7fa;
            --border-radius: 6px;
            --box-shadow: 0 2px 10px rgba(0,0,0,0.08);
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 0;
            background-color: var(--light-bg);
            color: #333;
            line-height: 1.6;
        }
        
        .container {
            max-width: 900px;
            margin: 40px auto;
            background: white;
            padding: 30px;
            border-radius: var(--border-radius);
            box-shadow: var(--box-shadow);
        }
        
        header {
            margin-bottom: 30px;
            border-bottom: 1px solid #eee;
            padding-bottom: 20px;
        }
        
        h1 {
            color: var(--primary-color);
            margin: 0 0 10px 0;
            font-weight: 600;
        }
        
        h2 {
            color: var(--primary-color);
            font-size: 1.5rem;
            margin: 30px 0 20px 0;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        
        .server-info {
            background-color: var(--light-bg);
            padding: 12px 15px;
            border-left: 4px solid var(--accent-color);
            border-radius: 4px;
            margin: 20px 0;
            font-size: 0.95rem;
        }
        
        form {
            background-color: white;
            padding: 25px;
            border-radius: var(--border-radius);
            margin-bottom: 30px;
            border: 1px solid #eee;
        }
        
        label {
            font-weight: 500;
            display: block;
            margin-bottom: 8px;
            color: var(--primary-color);
        }
        
        input[type="text"], textarea {
            width: 100%;
            padding: 12px;
            margin-bottom: 20px;
            border: 1px solid #ddd;
            border-radius: var(--border-radius);
            box-sizing: border-box;
            font-family: inherit;
            font-size: 0.95rem;
        }
        
        input[type="text"]:focus, textarea:focus {
            outline: none;
            border-color: var(--accent-color);
            box-shadow: 0 0 0 2px rgba(52, 152, 219, 0.2);
        }
        
        input[type="submit"] {
            background-color: var(--accent-color);
            color: white;
            padding: 12px 20px;
            border: none;
            border-radius: var(--border-radius);
            cursor: pointer;
            font-weight: 500;
            transition: background-color 0.2s;
        }
        
        input[type="submit"]:hover {
            background-color: #2980b9;
        }
        
        .messages {
            margin-top: 30px;
        }
        
        .message {
            border: 1px solid #eee;
            padding: 20px;
            border-radius: var(--border-radius);
            margin-bottom: 20px;
            background-color: white;
            box-shadow: var(--box-shadow);
        }
        
        .message-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 12px;
            padding-bottom: 12px;
            border-bottom: 1px solid #f0f0f0;
        }
        
        .message-name {
            font-weight: 600;
            color: var(--primary-color);
            font-size: 1.1rem;
        }
        
        .message-meta {
            display: flex;
            flex-direction: column;
            align-items: flex-end;
            gap: 5px;
        }
        
        .message-server {
            font-size: 0.85rem;
            color: #666;
        }
        
        .message-date {
            font-size: 0.85rem;
            color: #888;
        }
        
        .message-content {
            line-height: 1.6;
        }
        
        footer {
            text-align: center;
            margin-top: 40px;
            color: #777;
            font-size: 0.9rem;
        }

        .success {
            color: #27ae60;
            padding: 15px;
            background-color: #eafaf1;
            border-radius: var(--border-radius);
            margin: 25px 0;
            border-left: 4px solid #2ecc71;
        }
        
        .error {
            color: #e74c3c;
            padding: 15px;
            background-color: #fdf5f5;
            border-radius: var(--border-radius);
            margin: 25px 0;
            border-left: 4px solid #e74c3c;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <div class="server-info">
                Serveur actuel : <strong><?php echo $hostname; ?></strong> | Adresse IP : <strong><?php echo $server_ip; ?></strong>
            </div>
        </header>

        <?php if (isset($error)): ?>
            <div class="error"><?php echo $error; ?></div>
        <?php endif; ?>
        
        <?php if (isset($success)): ?>
            <div class="success"><?php echo $success; ?></div>
        <?php endif; ?>
        
        <form action="/" method="post">
            <h2>Laissez un message</h2>
            <label for="nom">Nom</label>
            <input type="text" id="nom" name="nom" required>
            
            <label for="message">Message</label>
            <textarea id="message" name="message" rows="4" required></textarea>
            
            <input type="submit" value="Envoyer">
        </form>
        
        <div class="messages">
            <h2>Messages récents</h2>
            <?php
            try {
                $conn = new mysqli('192.168.56.20', 'webuser', 'webpass', 'webappdb');
                
                if ($conn->connect_error) {
                    throw new Exception($conn->connect_error);
                }
                
                $result = $conn->query("SELECT nom, message, date_creation, serveur FROM messages ORDER BY date_creation DESC LIMIT 5");
                
                if ($result && $result->num_rows > 0) {
                    while($row = $result->fetch_assoc()) {
                        echo "<div class='message'>";
                        echo "<div class='message-header'>";
                        echo "<span class='message-name'>" . htmlspecialchars($row["nom"]) . "</span>";
                        echo "<div class='message-meta'>";
                        echo "<span class='message-server'>Serveur: " . htmlspecialchars($row["serveur"]) . "</span>";
                        echo "<span class='message-date'>" . $row["date_creation"] . "</span>";
                        echo "</div>";
                        echo "</div>";
                        echo "<div class='message-content'>" . nl2br(htmlspecialchars($row["message"])) . "</div>";
                        echo "</div>";
                    }
                } else {
                    echo "<p>Aucun message pour le moment.</p>";
                }
                
                $conn->close();
            } catch (Exception $e) {
                echo "<div style='color: #e74c3c; padding: 15px; background-color: #fdf5f5; border-radius: 4px; margin: 20px 0;'>
                      Erreur de connexion à la base de données : " . $e->getMessage() . "</div>";
            }
            ?>
        </div>
    </div>
</body>
</html>
EOL

# Configuration des permissions
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/

# Redémarrage d'Apache
systemctl restart apache2

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

# Démarrer et activer les services
systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter

echo "[INFO] Serveur web configuré avec succès"