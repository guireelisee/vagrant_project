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
    lb.vm.network "private_network", ip: "192.168.56.10" # Définir l'adresse IP du lb
    lb.vm.provision "shell", path: "setup_lb.sh" # Provision dans le fichier bash
  end







end
