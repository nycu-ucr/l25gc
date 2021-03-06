# !/bin/bash  
# Automatically setup the free5GC experiment

node_name=$(hostname)

workdir=$(pwd)
echo "Working directory is $workdir"
cd $workdir

echo "Start to configure free5GC on $node_name ..."

echo "========= Check whether GO is installed ========="
if command -v go >/dev/null 2>&1; then
    version=$(go version | awk '{print $3}')
    if [ $version == 'go1.14.4' ]; then
        echo "Current go version is $version"
    else
        echo 'exists go, remove the existing version and install Go 1.14.4:'
        # this assumes your current version of Go is in the default location
        sudo rm -rf /usr/local/go
        wget https://dl.google.com/go/go1.14.4.linux-amd64.tar.gz
        sudo tar -C /usr/local -zxvf go1.14.4.linux-amd64.tar.gz
        rm go1.14.4.linux-amd64.tar.gz
    fi
else
    echo 'no exists go'
    wget https://dl.google.com/go/go1.14.4.linux-amd64.tar.gz
    sudo tar -C /usr/local -zxvf go1.14.4.linux-amd64.tar.gz
    mkdir -p ~/go/{bin,pkg,src}
    # The following assume that your shell is bash
    echo 'export GOPATH=$HOME/go' >> ~/.bashrc
    echo 'export GOROOT=/usr/local/go' >> ~/.bashrc
    echo 'export PATH=$PATH:$GOPATH/bin:$GOROOT/bin' >> ~/.bashrc
    echo 'export GO111MODULE=auto' >> ~/.bashrc
    source ~/.bashrc
    rm go1.14.4.linux-amd64.tar.gz
fi

echo "========= Install control-plane supporting packages ========="
sudo apt -y update
sudo apt -y install mongodb wget git
sudo systemctl start mongodb

echo "========= Install user-plane supporting packages ========="
# sudo apt -y update
sudo apt -y install git gcc g++ cmake autoconf libtool pkg-config libmnl-dev libyaml-dev
go get -u github.com/sirupsen/logrus

echo "========= Install gtp5g  ========="
cd $HOME
git clone https://github.com/free5gc/gtp5g.git
cd $HOME/gtp5g
git checkout v0.4.0
make
sudo make install

echo "========= Sync and Update submoudle ========="
cd $workdir
git submodule sync
git submodule update --init

echo "========= Build Kernel free5GC ========="
cd $workdir/kernel-free5gc3.0.5
git submodule sync
git submodule update --init

echo "Build smf"
make smf
echo "Build amf"
make amf
echo "Build nssf"
make nssf
echo "Build pcf"
make pcf
echo "Build nrf"
make nrf
echo "Build ausf"
make ausf
echo "Build udm"
make udm
echo "Build udr"
make udr
echo "Build UPF"
make upf

echo "========= free5GC is set up ========="
