#!/bin/bash

# Update package lists
sudo apt update

# Install Git
# sudo apt install -y git

# Install Docker
sudo apt install -y docker.io

# Install .NET 8
wget https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
sudo apt update
sudo apt install -y dotnet-sdk-8.0

# Install NVM and Node.js
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install node
nvm use node

# Install Visual Studio Code
sudo snap install --classic code

# Install Postman
sudo snap install postman

# Install Google Chrome
sudo apt install -y chromium-browser

# Install pgAdmin
sudo apt install -y pgadmin4

# Install Terminator (multi-window terminal)
sudo apt install -y terminator

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Install VMware (if not already in a virtual machine)
if ! command -v vmware &> /dev/null
then
    wget https://download3.vmware.com/software/WKST-PLAYER-1623-LX/VMware-Player-Full-16.2.3-19200509.x86_64.bundle
    chmod +x VMware-Player-Full-16.2.3-19200509.x86_64.bundle
    sudo ./VMware-Player-Full-16.2.3-19200509.x86_64.bundle
    rm VMware-Player-Full-16.2.3-19200509.x86_64.bundle
fi

# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Install MongoDB
sudo apt install -y mongodb

# Install Curl
sudo apt install -y curl

# Install Python and pip
sudo apt install -y python3 python3-pip

# Install Django
pip3 install django

# Install Ansible
sudo apt install -y ansible

# Install Kubernetes CLI (kubectl)
sudo snap install kubectl --classic

# Install Terraform
sudo apt install -y terraform

# Install AWS CLI
sudo apt install -y awscli

# Install Google Cloud SDK
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
sudo apt update && sudo apt install -y google-cloud-sdk

echo "Installation completed successfully!"