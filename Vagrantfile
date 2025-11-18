Vagrant.configure("2") do |config|
  # Imagen base de Ubuntu 22.04
  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "cloudnova-dev"

  # Carpeta compartida: el directorio actual se monta como /vagrant dentro de la VM
  config.vm.synced_folder ".", "/vagrant"

  # Puertos para acceder desde tu host
  config.vm.network "forwarded_port", guest: 80, host: 8080    # HTTP app
  config.vm.network "forwarded_port", guest: 443, host: 8443   # HTTPS app
  config.vm.network "forwarded_port", guest: 9090, host: 9090  # Prometheus
  config.vm.network "forwarded_port", guest: 9100, host: 9100  # Node Exporter
  config.vm.network "forwarded_port", guest: 3000, host: 3000  # Grafana

  # Recursos de la VM
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "4096"
    vb.cpus = 2
  end

  # Provisioning: instala Docker y herramientas básicas
  config.vm.provision "shell", inline: <<-'SHELL'
    # Actualizar sistema
    apt-get update -y
    apt-get upgrade -y

    # Herramientas básicas
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release git

    # Repo oficial de Docker
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -y

    # Instalar Docker + plugin docker compose
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Agregar usuario vagrant al grupo docker
    usermod -aG docker vagrant

    systemctl enable docker
    systemctl start docker
  SHELL
end
