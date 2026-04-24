Vagrant.configure("2") do |config|

  config.vm.synced_folder "./configs", "/configs"

  # -------------------------
  # SENDER
  # -------------------------
  config.vm.define "sender" do |sender|
    sender.vm.box = "ubuntu/jammy64"
    sender.vm.hostname = "mail.mysender.com"
    sender.vm.network "private_network", ip: "192.168.56.10"
    sender.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.name = "Sender"
    end
    sender.vm.provision "shell", path: "provision/sender.sh"
  end

  # -------------------------
  # RECEIVER
  # -------------------------
  config.vm.define "receiver" do |receiver|
    receiver.vm.box = "ubuntu/jammy64"
    receiver.vm.hostname = "mail.myreceiver.com"
    receiver.vm.network "private_network", ip: "192.168.56.20"
    receiver.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.name = "Receiver"
    end
    receiver.vm.provision "shell", path: "provision/receiver.sh"
  end

  # -------------------------
  # USER (Kali)
  # -------------------------
  config.vm.define "user" do |user|
    user.vm.box = "kalilinux/rolling"
    user.vm.hostname = "user"
    user.vm.network "private_network", ip: "192.168.56.30"
    user.vm.provider "virtualbox" do |vb|
      vb.memory = 4096
      vb.gui = true
      vb.name = "User_GUI"
    end
    user.vm.provision "shell", path: "provision/user.sh"
    user.vm.provision "shell", inline: "chmod 600 /configs/key/id_lab && chown vagrant:vagrant /configs/key/id_lab"
  end

end