# Docker Installation Guide

Complete terminal/command-line instructions for installing Docker on Windows, macOS, and Linux.

---

## Table of Contents

1. [Windows](#windows)
2. [macOS](#macos)
3. [Linux](#linux)
   - [Ubuntu / Debian](#ubuntu--debian)
   - [Fedora](#fedora)
   - [CentOS / RHEL](#centos--rhel)
   - [Arch Linux](#arch-linux)
4. [Verify Installation](#verify-installation)
5. [Post-Installation](#post-installation)

---

## Windows

### Option 1: Using Winget (Windows Package Manager)

Open **PowerShell as Administrator** and run:

```powershell
# Install Docker Desktop using winget
winget install Docker.DockerDesktop

# Restart your computer
Restart-Computer
```

### Option 2: Using Chocolatey

```powershell
# Install Chocolatey (if not installed)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Docker Desktop
choco install docker-desktop -y

# Restart your computer
Restart-Computer
```

### Option 3: Direct Download via PowerShell

```powershell
# Download Docker Desktop installer
Invoke-WebRequest -Uri "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe" -OutFile "$env:TEMP\DockerDesktopInstaller.exe"

# Run the installer (silent install)
Start-Process -FilePath "$env:TEMP\DockerDesktopInstaller.exe" -ArgumentList "install", "--quiet", "--accept-license" -Wait

# Restart your computer
Restart-Computer
```

### Enable WSL 2 (Required for Docker on Windows)

```powershell
# Run PowerShell as Administrator

# Enable WSL
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# Enable Virtual Machine Platform
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Restart computer
Restart-Computer

# After restart, set WSL 2 as default
wsl --set-default-version 2

# Install WSL (includes Linux kernel)
wsl --install
```

### Start Docker Desktop (Windows)

```powershell
# Start Docker Desktop
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"

# Wait for Docker to be ready (check status)
docker info
```

---

## macOS

### Option 1: Using Homebrew (Recommended)

```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# For Apple Silicon Macs, add Homebrew to PATH
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Install Docker Desktop
brew install --cask docker

# Start Docker Desktop
open /Applications/Docker.app

# Wait for Docker to start (whale icon stops animating in menu bar)
# Then verify
docker --version
```

### Option 2: Direct Download via Terminal

```bash
# For Apple Silicon (M1/M2/M3)
curl -o ~/Downloads/Docker.dmg "https://desktop.docker.com/mac/main/arm64/Docker.dmg"

# For Intel Macs
# curl -o ~/Downloads/Docker.dmg "https://desktop.docker.com/mac/main/amd64/Docker.dmg"

# Mount the DMG
hdiutil attach ~/Downloads/Docker.dmg

# Copy to Applications
cp -R "/Volumes/Docker/Docker.app" /Applications/

# Unmount
hdiutil detach "/Volumes/Docker"

# Start Docker
open /Applications/Docker.app

# Clean up
rm ~/Downloads/Docker.dmg
```

### Option 3: Using MacPorts

```bash
# Install MacPorts first from https://www.macports.org/install.php
# Then install Docker
sudo port install docker docker-compose

# Note: This installs Docker Engine, not Docker Desktop
# You'll need to start the daemon manually
sudo dockerd &
```

### Check Mac Architecture

```bash
# Check if you have Apple Silicon or Intel
uname -m
# arm64 = Apple Silicon (M1/M2/M3)
# x86_64 = Intel
```

---

## Linux

### Ubuntu / Debian

```bash
# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again
sudo apt-get update

# Install Docker Engine, CLI, and plugins
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group (run without sudo)
sudo usermod -aG docker $USER

# Apply group changes
newgrp docker

# Verify installation
docker --version
docker compose version
```

#### Ubuntu One-Liner (Convenience Script)

```bash
# WARNING: Only use on fresh installations or for testing
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker
```

### Debian

```bash
# Update and install prerequisites
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

# Add Docker GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Fedora

```bash
# Remove old versions (if any)
sudo dnf remove docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-selinux \
    docker-engine-selinux \
    docker-engine

# Install dnf-plugins-core
sudo dnf -y install dnf-plugins-core

# Add Docker repository
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

# Install Docker
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group
sudo usermod -aG docker $USER

# Apply group changes
newgrp docker

# Verify installation
docker --version
docker compose version
```

### CentOS / RHEL

```bash
# Remove old versions
sudo yum remove docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-engine

# Install required packages
sudo yum install -y yum-utils

# Add Docker repository
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group
sudo usermod -aG docker $USER

# Apply group changes
newgrp docker

# Verify installation
docker --version
docker compose version
```

### RHEL 8/9 (Using Podman as Alternative)

```bash
# RHEL includes Podman by default (Docker-compatible)
sudo dnf install -y podman podman-compose

# Create alias for docker commands
echo 'alias docker=podman' >> ~/.bashrc
echo 'alias docker-compose=podman-compose' >> ~/.bashrc
source ~/.bashrc

# Verify
podman --version
```

### Arch Linux

```bash
# Update system
sudo pacman -Syu

# Install Docker
sudo pacman -S docker docker-compose

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group
sudo usermod -aG docker $USER

# Apply group changes
newgrp docker

# Verify installation
docker --version
docker compose version
```

### openSUSE

```bash
# Install Docker
sudo zypper install docker docker-compose

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group
sudo usermod -aG docker $USER

# Apply group changes
newgrp docker

# Verify installation
docker --version
docker compose version
```

### Alpine Linux

```bash
# Update package index
apk update

# Install Docker
apk add docker docker-compose

# Start Docker service
rc-service docker start
rc-update add docker boot

# Add your user to docker group
addgroup $USER docker

# Verify installation
docker --version
docker-compose --version
```

---

## Verify Installation

Run these commands on any platform to verify Docker is installed correctly:

```bash
# Check Docker version
docker --version

# Check Docker Compose version
docker compose version

# Check Docker is running
docker info

# Run hello-world test container
docker run hello-world

# Check Docker can pull images
docker pull alpine
docker run alpine echo "Docker is working!"

# Clean up test containers
docker system prune -f
```

Expected output for `docker --version`:
```
Docker version 24.0.x, build xxxxxxx
```

Expected output for `docker compose version`:
```
Docker Compose version v2.x.x
```

---

## Post-Installation

### Run Docker Without Sudo (Linux)

```bash
# Create docker group (if it doesn't exist)
sudo groupadd docker

# Add your user to docker group
sudo usermod -aG docker $USER

# Activate changes to groups
newgrp docker

# Verify you can run docker without sudo
docker run hello-world
```

### Configure Docker to Start on Boot

```bash
# Linux (systemd)
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

# To disable auto-start
sudo systemctl disable docker.service
sudo systemctl disable containerd.service
```

### Configure Docker Resource Limits (Optional)

```bash
# Create or edit Docker daemon configuration
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 64000,
      "Soft": 64000
    }
  }
}
EOF

# Restart Docker to apply changes
sudo systemctl restart docker
```

### Install Docker Compose Standalone (If Needed)

If `docker compose` (plugin) doesn't work, install standalone `docker-compose`:

```bash
# Download latest docker-compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make it executable
sudo chmod +x /usr/local/bin/docker-compose

# Verify
docker-compose --version
```

---

## Troubleshooting

### Docker Daemon Not Running

```bash
# Check Docker status
sudo systemctl status docker

# Start Docker
sudo systemctl start docker

# View Docker logs
sudo journalctl -u docker.service
```

### Permission Denied

```bash
# Error: permission denied while trying to connect to Docker daemon socket

# Fix: Add user to docker group
sudo usermod -aG docker $USER

# Then either logout/login or run:
newgrp docker
```

### WSL 2 Issues (Windows)

```powershell
# Update WSL
wsl --update

# Set WSL 2 as default
wsl --set-default-version 2

# List installed distributions
wsl -l -v

# Restart WSL
wsl --shutdown
```

### Docker Desktop Won't Start (macOS)

```bash
# Reset Docker Desktop
rm -rf ~/Library/Group\ Containers/group.com.docker
rm -rf ~/Library/Containers/com.docker.docker
rm -rf ~/.docker

# Reinstall
brew uninstall --cask docker
brew install --cask docker
```

### Disk Space Issues

```bash
# Check Docker disk usage
docker system df

# Clean up unused resources
docker system prune -a

# Remove all unused volumes
docker volume prune

# Remove all stopped containers
docker container prune

# Remove all unused images
docker image prune -a
```

---

## Next Steps

After Docker is installed and running, you can install the MS ABC application:

```bash
# Clone the repository
git clone https://github.com/yourusername/ms-abc-app.git
cd ms-abc-app

# Run the installer
chmod +x install.sh
./install.sh
```

See the main [README.md](README.md) for full application installation instructions.
