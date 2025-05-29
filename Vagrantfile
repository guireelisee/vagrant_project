# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024" # 1GB de RAM par defaut
    vb.cpus = 1 # 1 CPU par defaut
  end

  # Load Balancer
  config.vm.define "lb" do |lb|
    lb.vm.hostname = "lb"
    lb.vm.network "private_network", ip: "192.168.56.10" # Définir l'adresse IP de lb
    lb.vm.provision "shell", path: "setup_lb.sh" # Provision dans le fichier bash
  end

  # Serveurs Web
  config.vm.define "web1" do |web1|
    web1.vm.hostname = "web1"
    web1.vm.network "private_network", ip: "192.168.56.11"
    web1.vm.provision "shell", path: "setup_web.sh"
  end

  config.vm.define "web2" do |web2|
    web2.vm.hostname = "web2"
    web2.vm.network "private_network", ip: "192.168.56.12"
    web2.vm.provision "shell", path: "setup_web.sh"
  end

  # Base de Données Maître
  config.vm.define "db-master" do |dbm|
    dbm.vm.hostname = "db-master"
    dbm.vm.network "private_network", ip: "192.168.56.20"
    dbm.vm.provision "shell", path: "setup_db_master.sh"
    # Augmenter les ressources pour le serveur de base de données
    dbm.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
    end
  end

  # Base de Données Esclave
  config.vm.define "db-slave" do |dbs|
    dbs.vm.hostname = "db-slave"
    dbs.vm.network "private_network", ip: "192.168.56.21"
    dbs.vm.provision "shell", path: "setup_db_slave.sh"
    # Augmenter les ressources pour le serveur de base de données
    dbs.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
    end
  end

  # Serveur de Monitoring
  config.vm.define "monitoring" do |mon|
    mon.vm.hostname = "monitoring"
    mon.vm.network "private_network", ip: "192.168.56.30"
    mon.vm.provision "shell", path: "setup_monitoring.sh"
    # Plus de ressources pour Prometheus et Grafana
    mon.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
    end
  end

  # Client pour tester
  config.vm.define "client" do |client|
    client.vm.hostname = "client"
    client.vm.network "private_network", ip: "192.168.56.100"
  end

end
