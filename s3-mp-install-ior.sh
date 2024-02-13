#!/bin/bash
exec > >(tee /var/log/ior-install.log|logger -t user-data -s 2>/dev/console) 2>&1
echo `date +'%F %R:%S'` "INFO: Logging Setup" >&2

echo "installing IOR"
set -u

function fetch_code(){
    echo "fetch github source code for ior"
    mkdir -p /shared/ior
    cd ~
    git clone https://github.com/hpc/ior.git
    cd ior
    #git checkout io500-sc19
}

function load_modules(){
    echo "loading intel modules"
    source /etc/profile.d/modules.sh
    module -v load intelmpi
}

function install_compile_ior()
{
    # install
    load_modules
    echo "bootstrap ior"
    cd ~/ior
    ./bootstrap
    mkdir build;cd build
    echo "configure ior"
    ../configure --with-mpiio --prefix=/shared/ior 
    echo "building ior"
    make -j 10
    make install
}

function set_env(){
    echo "setting environment"
    export PATH=$PATH:/shared/ior/bin
    echo 'export PATH=$PATH:/shared/ior/bin' >> ~/.bashrc
    if [ -z "${LD_LIBRARY_PATH+x}" ]; then
        export LD_LIBRARY_PATH=/shared/ior/lib
        echo 'export LD_LIBRARY_PATH=/shared/ior/lib' >> ~/.bashrc
    else
        export LD_LIBRARY_PATH=/shared/ior/lib:$LD_LIBRARY_PATH
        echo 'export LD_LIBRARY_PATH=/shared/ior/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
    fi
}

function set_aws_config(){
    aws configure set default.s3.max_concurrent_requests 100
}

function run(){
    fetch_code
    install_compile_ior
    set_aws_config
    set_env
}

run && exit 0