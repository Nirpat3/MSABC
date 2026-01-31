#!/bin/bash

#############################################
# MS ABC Quick Start
# Double-click to start the application
#############################################

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change to the app directory
cd "$SCRIPT_DIR"

# Verify we're in the right directory
if [ ! -f "package.json" ]; then
    echo "Error: Could not find package.json in $SCRIPT_DIR"
    echo "Please run this script from the ms-abc-app directory."
    read -p "Press Enter to exit..."
    exit 1
fi

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     MS ABC Retailer Management System        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Running from: ${SCRIPT_DIR}"
echo ""

# Load environment
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

FRONTEND_PORT=${FRONTEND_PORT:-3000}
BACKEND_PORT=${BACKEND_PORT:-3001}

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${YELLOW}Starting Docker Desktop...${NC}"
    open -a Docker

    # Wait for Docker to start (max 60 seconds)
    echo -e "${YELLOW}Waiting for Docker to be ready...${NC}"
    COUNTER=0
    while ! docker info &> /dev/null; do
        sleep 2
        COUNTER=$((COUNTER + 2))
        if [ $COUNTER -ge 60 ]; then
            echo -e "${RED}Docker failed to start within 60 seconds.${NC}"
            echo -e "${RED}Please start Docker Desktop manually and try again.${NC}"
            read -p "Press Enter to exit..."
            exit 1
        fi
        echo -e "${YELLOW}  Waiting... ($COUNTER seconds)${NC}"
    done
    echo -e "${GREEN}✓ Docker is ready${NC}"
fi

echo -e "${YELLOW}Starting database and services...${NC}"

# Start PostgreSQL and Redis
docker compose up -d postgres redis

# Wait for database to be ready
echo -e "${YELLOW}Waiting for database to be ready...${NC}"
sleep 3

# Create automatic backup on startup (if database has data)
BACKUP_DIR="$SCRIPT_DIR/backups"
mkdir -p "$BACKUP_DIR"
if docker ps --format '{{.Names}}' | grep -q 'ms-abc-db'; then
    BACKUP_FILE="${BACKUP_DIR}/auto_startup_$(date +%Y%m%d_%H%M%S).sql"
    if docker exec ms-abc-db pg_dump -U ${POSTGRES_USER:-msabc} ${POSTGRES_DB:-ms_abc_db} > "$BACKUP_FILE" 2>/dev/null; then
        if [ -f "$BACKUP_FILE" ] && [ -s "$BACKUP_FILE" ]; then
            echo -e "${GREEN}✓ Auto-backup created${NC}"
        else
            rm -f "$BACKUP_FILE"
        fi
    fi

    # Cleanup: keep only last 50 backups
    ls -1t "$BACKUP_DIR"/*.sql 2>/dev/null | tail -n +51 | xargs rm -f 2>/dev/null
fi

# Start backend and frontend
echo -e "${YELLOW}Starting backend and frontend...${NC}"
npm run dev &

# Wait for services to start
echo -e "${YELLOW}Waiting for services to initialize...${NC}"
sleep 5

# Open browser
echo -e "${GREEN}Opening browser...${NC}"
open "http://localhost:${FRONTEND_PORT}"

echo ""
echo -e "${GREEN}✓ MS ABC is running!${NC}"
echo -e "${BLUE}Frontend: http://localhost:${FRONTEND_PORT}${NC}"
echo -e "${BLUE}Backend:  http://localhost:${BACKEND_PORT}${NC}"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop the application${NC}"
echo ""

# Keep the terminal open and wait for the background process
wait
