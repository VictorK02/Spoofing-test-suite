Vagrant.configure("2") do |config|

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 4096
    vb.cpus = 2
  end

  # -------------------------
  # Legitimate Sender Domain
  # -------------------------
  config.vm.define "sender" do |sender|
    sender.vm.box = "ubuntu/jammy64"
    sender.vm.hostname = "mail.mysender.com"
    sender.vm.network "private_network", ip: "192.168.56.10"
    sender.vm.provision "shell", path: "provision/sender.sh"
  end

  # -------------------------
  # Receiver (Target)
  # -------------------------
  config.vm.define "receiver" do |receiver|
    receiver.vm.box = "ubuntu/jammy64"
    receiver.vm.hostname = "mail.myreceiver.com"
    receiver.vm.network "private_network", ip: "192.168.56.20"
    receiver.vm.provision "shell", path: "provision/receiver.sh"
  end

  # -------------------------
  # Attacker (Kali)
  # -------------------------
  config.vm.define "attacker" do |attacker|
    attacker.vm.box = "kalilinux/rolling"
    attacker.vm.hostname = "attacker.com"
    attacker.vm.network "private_network", ip: "192.168.56.30"
    attacker.vm.provision "shell", path: "provision/attacker.sh"
  end
  
# GLOBAL PROVISIONING: Sets password and opens SSH for your friend
  config.vm.provision "shell", inline: <<-SHELL
    # 1. Set the password for the vagrant user to 'vagrant'
    echo "vagrant:vagrant" | chpasswd
    
    # 2. Enable Password Authentication in SSH config
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    
    # 3. Specifically for Kali: Ensure SSH is allowed
    systemctl enable ssh
    systemctl restart ssh
  SHELL


  config.vm.synced_folder "./configs", "/configs"

  
end