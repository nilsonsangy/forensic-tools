# -*- mode: ruby -*-
# vi: set ft=ruby :

# =============================================================================
# Forensic Tools - Laboratorio 
# =============================================================================
# Cenario: 1 VM Windows + 1 VM Linux, ambas leves e com interface grafica,
# ligadas por uma rede interna isolada (host-only) e com saida para a
# Internet via NAT do VMware Workstation Pro.
#
# Provider: VMware Workstation Pro (plugin vagrant-vmware-desktop)
#
# Pre-requisitos:
#   1. VMware Workstation Pro instalado
#   2. Vagrant instalado (https://www.vagrantup.com)
#   3. Plugin:  vagrant plugin install vagrant-vmware-desktop
#   4. Licenca do plugin (paga, da HashiCorp): vagrant plugin license
#
# Uso:
#   vagrant up                 # sobe as duas VMs
#   vagrant up win10           # sobe apenas a Windows
#   vagrant up ubuntu          # sobe apenas a Linux
#   vagrant halt / vagrant destroy
#
# Rede interna (isolada, somente entre as VMs e o host):
#   Windows: 192.168.56.10
#   Linux:   192.168.56.20
# Alem da rede interna, cada VM mantem a interface NAT padrao do VMware,
# que garante acesso a Internet (para updates, downloads de ferramentas etc.).
# =============================================================================

Vagrant.configure("2") do |config|

  # Pasta do repositorio fica sincronizada dentro das VMs:
  #   - Linux:   /vagrant
  #   - Windows: C:\vagrant
  # Assim os coletores (windows_collector.ps1, linux_collector.sh etc.)
  # ficam disponiveis diretamente nas maquinas de analise.

  # ---------------------------------------------------------------------------
  # VM 1 - Windows 10 (leve, com GUI) - alvo de coleta de evidencias Windows
  # Box: gusztavvargadr/windows-10 (Windows 10 Enterprise Evaluation, GUI)
  # Provider vmware_desktop disponivel no Vagrant Cloud.
  # ---------------------------------------------------------------------------
  config.vm.define "win10" do |win|
    win.vm.box = "gusztavvargadr/windows-10"
    win.vm.hostname = "forensic-win10"

    # Rede interna isolada (host-only)
    win.vm.network "private_network", ip: "192.168.56.10"

    # Comunicacao via WinRM (padrao para boxes Windows)
    win.vm.communicator = "winrm"
    win.winrm.username = "vagrant"
    win.winrm.password = "vagrant"

    win.vm.provider "vmware_desktop" do |v|
      v.gui = true                       # abre com interface grafica
      v.linked_clone = true              # clone rapido, economiza disco
      v.vmx["memsize"] = "4096"          # 4 GB RAM (minimo confortavel p/ Win10)
      v.vmx["numvcpus"] = "2"
      v.vmx["displayName"] = "Forensic-Win10"
    end
  end

  # ---------------------------------------------------------------------------
  # VM 2 - Ubuntu Desktop 20.04 (leve, com GUI) - alvo de coleta em Linux
  # Box: peru/ubuntu-20.04-desktop-amd64 (Ubuntu Desktop, GUI)
  # Provider vmware_desktop disponivel no Vagrant Cloud.
  # ---------------------------------------------------------------------------
  config.vm.define "ubuntu" do |lnx|
    lnx.vm.box = "peru/ubuntu-20.04-desktop-amd64"
    lnx.vm.hostname = "forensic-ubuntu"

    # Rede interna isolada (host-only)
    lnx.vm.network "private_network", ip: "192.168.56.20"

    lnx.vm.provider "vmware_desktop" do |v|
      v.gui = true                       # abre com interface grafica
      v.linked_clone = true
      v.vmx["memsize"] = "2048"          # 2 GB RAM (suficiente p/ Ubuntu Desktop)
      v.vmx["numvcpus"] = "2"
      v.vmx["displayName"] = "Forensic-Ubuntu"
    end

    # Ferramentas basicas de forense/coleta ja instaladas no provisionamento
    lnx.vm.provision "shell", inline: <<-SHELL
      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get install -y --no-install-recommends \
        tcpdump tshark sleuthkit autopsy \
        volatility3 dc3dd guymager \
        net-tools lsof strace
    SHELL
  end

end
