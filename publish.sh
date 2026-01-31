#!/bin/bash

#############################################
# MS ABC - Publish Docker Images
# Builds and pushes images to Docker Hub
#############################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration - CHANGE THESE
DOCKER_USERNAME="${DOCKER_USERNAME:-}"
VERSION="${VERSION:-latest}"

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     MS ABC - Publish Docker Images to Registry               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if username is provided
if [ -z "$DOCKER_USERNAME" ]; then
    echo -e "${YELLOW}Enter your Docker Hub username:${NC}"
    read -r DOCKER_USERNAME
fi

if [ -z "$DOCKER_USERNAME" ]; then
    echo -e "${RED}Docker username is required${NC}"
    exit 1
fi

echo -e "${YELLOW}Publishing as: ${DOCKER_USERNAME}${NC}"
echo -e "${YELLOW}Version: ${VERSION}${NC}"
echo ""

# Login to Docker Hub
echo -e "${YELLOW}Logging in to Docker Hub...${NC}"
docker login

# Build images
echo -e "${YELLOW}Building Docker images...${NC}"
docker compose build --no-cache

# Tag images
echo -e "${YELLOW}Tagging images...${NC}"
docker tag ms-abc-app-backend:latest ${DOCKER_USERNAME}/ms-abc-backend:${VERSION}
docker tag ms-abc-app-frontend:latest ${DOCKER_USERNAME}/ms-abc-frontend:${VERSION}

# Also tag as latest if version is specified
if [ "$VERSION" != "latest" ]; then
    docker tag ms-abc-app-backend:latest ${DOCKER_USERNAME}/ms-abc-backend:latest
    docker tag ms-abc-app-frontend:latest ${DOCKER_USERNAME}/ms-abc-frontend:latest
fi

# Push images
echo -e "${YELLOW}Pushing images to Docker Hub...${NC}"
docker push ${DOCKER_USERNAME}/ms-abc-backend:${VERSION}
docker push ${DOCKER_USERNAME}/ms-abc-frontend:${VERSION}

if [ "$VERSION" != "latest" ]; then
    docker push ${DOCKER_USERNAME}/ms-abc-backend:latest
    docker push ${DOCKER_USERNAME}/ms-abc-frontend:latest
fi

# Update docker-compose.hub.yml with correct username
echo -e "${YELLOW}Updating docker-compose.hub.yml...${NC}"
sed -i.bak "s/yourusername/${DOCKER_USERNAME}/g" docker-compose.hub.yml
rm -f docker-compose.hub.yml.bak

echo ""
echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              Images Published Successfully! 🎉                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "Your images are now available at:"
echo -e "  ${BLUE}docker pull ${DOCKER_USERNAME}/ms-abc-backend:${VERSION}${NC}"
echo -e "  ${BLUE}docker pull ${DOCKER_USERNAME}/ms-abc-frontend:${VERSION}${NC}"
echo ""
echo -e "${YELLOW}To deploy on another machine:${NC}"
echo "  1. Copy these files to your server:"
echo "     - docker-compose.hub.yml"
echo "     - .env.example (rename to .env and configure)"
echo ""
echo "  2. Run:"
echo "     docker compose -f docker-compose.hub.yml up -d"
echo ""
