#!/bin/bash

# Run only first boot
test -f /first-boot-check && exit 0
touch /first-boot-check

# Install misc utilities
echo ":: Install misc utilities"
apt-get update
apt-get install -y --no-install-recommends tmux ranger less htop ruby


# Install Docker and Nvidia's runtime
echo ":: Install Docker"
wget https://download.docker.com/linux/debian/dists/stretch/pool/stable/amd64/containerd.io_1.2.6-3_amd64.deb
wget https://download.docker.com/linux/debian/dists/stretch/pool/stable/amd64/docker-ce-cli_19.03.1~3-0~debian-stretch_amd64.deb
wget https://download.docker.com/linux/debian/dists/stretch/pool/stable/amd64/docker-ce_19.03.1~3-0~debian-stretch_amd64.deb
dpkg -i containerd.io_1.2.6-3_amd64.deb
dpkg -i docker-ce-cli_19.03.1~3-0~debian-stretch_amd64.deb
dpkg -i docker-ce_19.03.1~3-0~debian-stretch_amd64.deb
systemctl enable --now docker

curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/ubuntu18.04/nvidia-docker.list > /etc/apt/sources.list.d/nvidia-docker.list
apt-get update
apt-get install -y nvidia-container-toolkit

# For now, use "deprecating" nvidia-container-runtime for docker-compose support
apt-get install -y nvidia-container-runtime
cat > /etc/docker/daemon.json <<XXX
{
    "runtimes": {
        "nvidia": {
            "path": "/usr/bin/nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
XXX
systemctl restart docker


# Install docker-compose
echo ":: Install Docker-compose"
apt-get install -y --no-install-recommends python3-pip python3-setuptools
python3 -m pip install docker-compose


# Install Nvidia driver
echo ":: Install Nvidia driver"
apt-get install -y --no-install-recommends \
  nvidia-headless-430 \
  nvidia-utils-430 \
  nvidia-modprobe
