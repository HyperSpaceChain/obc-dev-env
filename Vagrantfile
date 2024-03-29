# -*- mode: ruby -*-
# vi: set ft=ruby :

# This vagrantfile creates a VM with the development environment
# configured and ready to go.
#
# The setup script (env var $script) in this file installs docker.
# This is not in the setup.sh file because the docker install needs
# to be secure when running on a real linux machine.
# The docker environment that is installed by this script is not secure,
# it depends on the host being secure.
#
# At the end of the setup script in this file, a call is made
# to run setup.sh to create the developer environment.

# This is the mount point for the sync_folders of the source
SRCMOUNT = "/openchain"
HOST_GOPATH = ENV['GOPATH']

$script = <<SCRIPT
set -x

export DOCKER_STORAGE_BACKEND="#{ENV['DOCKER_STORAGE_BACKEND']}"

cd #{SRCMOUNT}/obc-dev-env
./setup.sh

SCRIPT

Vagrant.configure('2') do |config|
  config.vm.box = "obc/dev-env"
  config.vm.box_version = ENV['USE_LOCAL_BASEIMAGE'] ? "0":"0.2.1" # Vagrant does not support versioning local images, the local version is always implicitly version 0

  config.vm.network :forwarded_port, guest: 5000, host: 3000 # Openchain REST services
  config.vm.network :forwarded_port, guest: 30303, host: 30303 # Openchain gRPC services

  config.vm.synced_folder "..", "#{SRCMOUNT}"
  config.vm.synced_folder "#{HOST_GOPATH}/src/github.com/hyperledger-incubator/obc-peer", "/opt/gopath/src/github.com/hyperledger-incubator/obc-peer"

  config.vm.provider :virtualbox do |vb|
    vb.name = "hyperledger"
    vb.customize ['modifyvm', :id, '--memory', '4096']
    vb.cpus = 2

    storage_backend = ENV['DOCKER_STORAGE_BACKEND']
    case storage_backend
    when nil,"","aufs","AUFS"
      # No extra work to be done
    when "btrfs","BTRFS"
      # Add a second disk for the btrfs volume
      IO.popen("VBoxManage list systemproperties") { |f|

        success = false
        while line = f.gets do
          # Find the directory where the machine images are stored
          machine_folder = line.sub(/^Default machine folder:\s*/,"")

          if line != machine_folder
            btrfs_disk = File.join(machine_folder, vb.name, 'btrfs.vdi')

            unless File.exist?(btrfs_disk)
              # Create the disk if it doesn't already exist
              vb.customize ['createhd', '--filename', btrfs_disk, '--format', 'VDI', '--size', 20 * 1024]
            end

            # Add the disk to the VM
            vb.customize ['storageattach', :id, '--storagectl', 'SATAController', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', btrfs_disk]
            success = true

            break
          end
        end
        raise Vagrant::Errors::VagrantError.new, "Could not provision btrfs disk" if !success
      }
    else
      raise Vagrant::Errors::VagrantError.new, "Unknown storage backend type: #{storage_backend}"
    end

  end

  config.vm.provision :shell, inline: $script
end
