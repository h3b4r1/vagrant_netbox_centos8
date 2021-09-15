Vagrant.configure("2") do |config|
  config.vm.define "netbox" do |netbox|
    config.vm.box = "centos/8"
	config.vm.provider "virtualbox" do |vb|
		vb.memory = 2048
		vb.cpus = 2
	end
	netbox.vm.network "forwarded_port", guest: 80, host: 80
	netbox.vm.network "forwarded_port", guest: 443, host: 443
	netbox.vm.provision "shell", path: "./setup-centos.sh"
	netbox.vm.provision "shell", path: "./provision-netbox.sh"
  end
end