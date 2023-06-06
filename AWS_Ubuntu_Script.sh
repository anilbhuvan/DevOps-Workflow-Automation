#!/bin/bash

# sudo 
# SSD Volume Type
# ami-053b0d53c279acc90
# (64-bit (x86)) / ami-0a0c8eebcdd6dcbd0 (64-bit (Arm))

# Create a new user
sudo useradd -m project

# Set the password for the user
echo 'project:project' | sudo chpasswd

# Grant sudo privileges to the user
sudo usermod -aG sudo project

# Grant sudo privileges to ubuntu
sudo usermod -aG sudo ubuntu

# Configure passwordless sudo for the user
echo 'project ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/project

# Change permissions for the sudoers file
sudo chmod 0440 /etc/sudoers.d/project

# Update package lists
sudo apt update

# Install JDK
sudo apt install -y openjdk-17-jdk

# Install Maven
sudo apt install -y maven

# install nodejs
sudo apt install -y nodejs

# install npm
sudo apt install -y npm

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add the project user to docker group
sudo usermod -aG docker project
sudo usermod -aG docker ubuntu
# Cleanup
rm get-docker.sh

public_ip=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

docker run -d --name some-ghost -e NODE_ENV=development -e url=http://$public_ip:3001 -p 3001:2368 ghost

touch /home/ubuntu/script_completed