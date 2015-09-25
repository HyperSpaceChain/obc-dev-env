#!/bin/bash

helpme()
{
  cat <<HELPMEHELPME
Syntax: sudo $0

Installs the stuff needed to get the VirtualBox Ubuntu (or other similar Linux
host) into good shape to run our development environment.

This script needs to run as root.

The current directory must be the dev-env project directory.

HELPMEHELPME
}

if [[ "$1" == "-?" || "$1" == "-h" || "$1" == "--help" ]] ; then
  helpme
  exit 1
fi


set -e
set -x

cd /opt
git clone https://github.com/facebook/rocksdb.git
cd rocksdb

make shared_lib

cat <<EOF >/tmp/rocksLDLibrary.sh
export LD_LIBRARY_PATH="/opt/rocksdb:\$LD_LIBRARY_PATH"
EOF
sudo mv /tmp/rocksLDLibrary.sh /etc/profile.d/rocksLDLibrary.sh
sudo chmod 0755 /etc/profile.d/rocksLDLibrary.sh

sudo apt-get install -y libsnappy-dev
sudo apt-get install -y zlib1g-dev
sudo apt-get install -y libbz2-dev

CGO_CFLAGS="-I/opt/rocksdb/include" CGO_LDFLAGS="-L/opt/rocksdb -lrocksdb -lstdc++ -lm -lz -lbz2 -lsnappy" go get github.com/tecbot/gorocksdb