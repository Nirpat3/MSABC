#!/bin/bash

#############################################
# MS ABC Retailer Management System
# One-Click Install & Run
#############################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     MS ABC Retailer Management System - Quick Start         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

#############################################
# Step 1: Check prerequisites
#############################################
echo -e "${YELLOW}[1/7] Checking prerequisites...${NC}"

if ! command -v node &> /dev/null; then
    echo -e "${RED}Node.js is not installed. Please install Node.js >= 18.${NC}"
    exit 1
fi

NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo -e "${RED}Node.js >= 18 is required. Found: $(node -v)${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ Node.js $(node -v)${NC}"

if ! command -v npm &> /dev/null; then
    echo -e "${RED}npm is not installed.${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ npm $(npm -v)${NC}"

if ! command -v psql &> /dev/null; then
    echo -e "${RED}PostgreSQL is not installed. Please install PostgreSQL 14+.${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ PostgreSQL $(psql --version | grep -oP '\d+\.\d+')${NC}"

#############################################
# Step 2: Start PostgreSQL if not running
#############################################
echo -e "${YELLOW}[2/7] Ensuring PostgreSQL is running...${NC}"

if ! pg_isready -q 2>/dev/null; then
    echo "  Starting PostgreSQL..."
    sudo pg_ctlcluster 16 main start 2>/dev/null \
        || sudo systemctl start postgresql 2>/dev/null \
        || sudo service postgresql start 2>/dev/null \
        || { echo -e "${RED}Could not start PostgreSQL. Please start it manually.${NC}"; exit 1; }

    # Wait for PostgreSQL to be ready
    for i in {1..15}; do
        if pg_isready -q 2>/dev/null; then
            break
        fi
        sleep 1
    done

    if ! pg_isready -q 2>/dev/null; then
        echo -e "${RED}PostgreSQL failed to start.${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}  ✓ PostgreSQL is running${NC}"

#############################################
# Step 3: Set up database
#############################################
echo -e "${YELLOW}[3/7] Setting up database...${NC}"

DB_NAME="ms_abc_db"
DB_USER="msabc"
DB_PASS="msabc_dev_pass"

# Create user if it doesn't exist
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1 \
    || sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';" 2>/dev/null
echo -e "${GREEN}  ✓ Database user ready${NC}"

# Create database if it doesn't exist
sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'" | grep -q 1 \
    || sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" 2>/dev/null
echo -e "${GREEN}  ✓ Database ready${NC}"

# Grant privileges
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;" 2>/dev/null
sudo -u postgres psql -d "$DB_NAME" -c "GRANT ALL ON SCHEMA public TO $DB_USER;" 2>/dev/null

DATABASE_URL="postgresql://${DB_USER}:${DB_PASS}@localhost:5432/${DB_NAME}?schema=public"

#############################################
# Step 4: Create .env file
#############################################
echo -e "${YELLOW}[4/7] Configuring environment...${NC}"

ENV_FILE="packages/backend/.env"
if [ ! -f "$ENV_FILE" ]; then
    cat > "$ENV_FILE" << EOF
DATABASE_URL=${DATABASE_URL}
BACKEND_PORT=3001
EOF
    echo -e "${GREEN}  ✓ Created $ENV_FILE${NC}"
else
    # Ensure DATABASE_URL is set
    if ! grep -q "^DATABASE_URL=" "$ENV_FILE"; then
        echo "DATABASE_URL=${DATABASE_URL}" >> "$ENV_FILE"
    fi
    echo -e "${GREEN}  ✓ $ENV_FILE already exists${NC}"
fi

# Also create root .env for docker-compose compatibility
if [ ! -f ".env" ]; then
    cat > ".env" << EOF
DATABASE_URL=${DATABASE_URL}
POSTGRES_USER=${DB_USER}
POSTGRES_PASSWORD=${DB_PASS}
POSTGRES_DB=${DB_NAME}
POSTGRES_PORT=5432
BACKEND_PORT=3001
FRONTEND_PORT=5000
EOF
    echo -e "${GREEN}  ✓ Created root .env${NC}"
fi

export DATABASE_URL

#############################################
# Step 5: Install dependencies
#############################################
echo -e "${YELLOW}[5/7] Installing dependencies...${NC}"

npm install 2>&1 | tail -1
echo -e "${GREEN}  ✓ Dependencies installed${NC}"

#############################################
# Step 6: Set up database schema & seed
#############################################
echo -e "${YELLOW}[6/7] Setting up database schema...${NC}"

cd packages/backend

# Generate Prisma client
npx prisma generate 2>&1 | tail -1
echo -e "${GREEN}  ✓ Prisma client generated${NC}"

# Push schema to database
npx prisma db push --accept-data-loss 2>&1 | tail -1
echo -e "${GREEN}  ✓ Database schema applied${NC}"

# Seed the database
npx tsx prisma/seed.ts 2>&1 || true
echo -e "${GREEN}  ✓ Database seeded${NC}"

cd "$SCRIPT_DIR"

#############################################
# Step 7: Start the application
#############################################
echo -e "${YELLOW}[7/7] Starting the application...${NC}"
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗"
echo -e "║                    Setup Complete!                            ║"
echo -e "╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BLUE}Frontend:${NC}    http://localhost:5000"
echo -e "  ${BLUE}Backend API:${NC} http://localhost:3001"
echo -e "  ${BLUE}Health:${NC}      http://localhost:3001/api/health"
echo ""
echo -e "${YELLOW}Starting servers... (Ctrl+C to stop)${NC}"
echo ""

# Start backend and frontend concurrently
DATABASE_URL="$DATABASE_URL" npx concurrently \
    --names "backend,frontend" \
    --prefix-colors "blue,green" \
    "cd packages/backend && DATABASE_URL=$DATABASE_URL npx tsx src/index.ts" \
    "cd packages/frontend && npx vite --host 0.0.0.0 --port 5000"
