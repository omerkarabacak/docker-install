#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Parse command line arguments
DOCKER=false
COMPOSE=false
while [ $# -gt 0 ]; do
    case $1 in
        --with-docker)
            DOCKER=true
            ;;
        --with-compose)
            COMPOSE=true
            ;;
        *)
            echo -e "${RED}Invalid argument: $1${NC}"
            exit 1
            ;;
    esac
    shift
done

# Check if either Docker or Docker-compose needs to be installed
if ! $DOCKER && ! $COMPOSE; then
    echo -e "${RED}Error: No argument specified. Please specify --with-docker, --with-compose or both.${NC}"
    exit 1
fi

# Install Docker
if $DOCKER; then
    # Update the apt package index
    sudo apt-get update

    # Install dependencies
    sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Add Docker's stable repository
    echo \
        "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update the apt package index again
    sudo apt-get update

    # Install Docker
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io

    # Add the current user to the docker group
    sudo usermod -aG docker $USER

    echo -e "${GREEN}Docker has been installed.${NC}"
fi

# Install Docker-compose
if $COMPOSE; then
    # Download the current stable release of Docker-compose
    sudo curl -L "https://github.com/docker/compose/releases/download/$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

    # Make the downloaded file executable
    sudo chmod +x /usr/local/bin/docker-compose

    echo -e "${GREEN}Docker-compose has been installed.${NC}"
fi
