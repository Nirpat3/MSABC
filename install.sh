#!/bin/bash

#############################################
# MS ABC Retailer Management System
# One-Click Installation Script
#############################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     MS ABC Retailer Management System - Installation         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check for Docker
check_docker() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"

    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
        echo "Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo -e "${RED}Docker Compose is not installed. Please install Docker Compose.${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ Docker is installed${NC}"
}

# Create environment file
create_env_file() {
    echo -e "${YELLOW}Setting up environment configuration...${NC}"

    if [ -f .env ]; then
        echo -e "${YELLOW}Found existing .env file. Do you want to overwrite it? (y/N)${NC}"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "Keeping existing .env file"
            return
        fi
    fi

    # Generate secure password
    POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 24)

    cat > .env << EOF
# MS ABC Retailer Management System Configuration
# Generated on $(date)

#############################################
# Database Configuration
#############################################
POSTGRES_USER=msabc
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=ms_abc_db
POSTGRES_PORT=5433

#############################################
# Redis Configuration
#############################################
REDIS_PORT=6380

#############################################
# Application Ports
#############################################
BACKEND_PORT=3001
FRONTEND_PORT=3000

#############################################
# AI Configuration (for database optimization & forecasting)
# Uncomment and set your preferred AI provider
#############################################
# AI_PROVIDER=openai
# OPENAI_API_KEY=your-openai-api-key-here

# Or use Anthropic Claude
# AI_PROVIDER=anthropic
# ANTHROPIC_API_KEY=your-anthropic-api-key-here

#############################################
# Data Sync Configuration
#############################################
# Enable/disable automatic data sync
SYNC_ENABLED=true

# Sync interval: minutes, hourly, daily, weekly
SYNC_INTERVAL=daily

# Custom interval in minutes (used when SYNC_INTERVAL=minutes)
SYNC_INTERVAL_MINUTES=60

# Retry configuration
SYNC_RETRY_ATTEMPTS=3
SYNC_RETRY_DELAY_MS=60000
SYNC_RETRY_BACKOFF_MULTIPLIER=2

#############################################
# Forecast Configuration
#############################################
# Weekly forecast generation (day of week: 0=Sunday, 1=Monday, etc.)
FORECAST_DAY_OF_WEEK=1
FORECAST_HOUR=7

#############################################
# Database Optimization
#############################################
# How often to run AI database optimization (hours)
DB_OPTIMIZATION_INTERVAL_HOURS=24

# Enable AI-powered query analysis
AI_QUERY_OPTIMIZATION=true

#############################################
# Billing & Token Tracking
#############################################
# Track all AI API usage for billing
TRACK_TOKEN_USAGE=true

# Monthly token budget (0 = unlimited)
MONTHLY_TOKEN_BUDGET=0

# Alert when usage exceeds percentage of budget
TOKEN_BUDGET_ALERT_THRESHOLD=80
EOF

    echo -e "${GREEN}✓ Environment file created${NC}"
    echo -e "${YELLOW}Note: Edit .env file to add your AI API keys for advanced features${NC}"
}

# Create required directories
create_directories() {
    echo -e "${YELLOW}Creating required directories...${NC}"

    mkdir -p backups
    mkdir -p logs
    mkdir -p generated-forms

    echo -e "${GREEN}✓ Directories created${NC}"
}

# Check if this is an upgrade (existing data)
check_existing_installation() {
    # Use docker compose (v2) or docker-compose (v1)
    if docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        COMPOSE_CMD="docker-compose"
    fi

    # Check if database volume exists with data
    if docker volume ls | grep -q "ms-abc-app_postgres_data"; then
        echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}Existing installation detected!${NC}"
        echo -e "${GREEN}Your data will be preserved during this upgrade.${NC}"
        echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"

        # Create automatic backup before upgrade
        echo -e "${YELLOW}Creating automatic backup before upgrade...${NC}"
        mkdir -p backups
        BACKUP_FILE="backups/pre_upgrade_$(date +%Y%m%d_%H%M%S).sql"

        # Check if database container is running
        if docker ps | grep -q "ms-abc-db"; then
            docker exec ms-abc-db pg_dump -U ${POSTGRES_USER:-msabc} ${POSTGRES_DB:-ms_abc_db} > "$BACKUP_FILE" 2>/dev/null || true
            if [ -f "$BACKUP_FILE" ] && [ -s "$BACKUP_FILE" ]; then
                echo -e "${GREEN}✓ Backup created: $BACKUP_FILE${NC}"
            fi
        fi

        IS_UPGRADE=true
    else
        IS_UPGRADE=false
    fi
}

# Build and start containers
start_services() {
    echo -e "${YELLOW}Building and starting services...${NC}"

    # Build images (use cache for upgrades to be faster)
    if [ "$IS_UPGRADE" = true ]; then
        echo "Building Docker images (using cache for faster upgrade)..."
        $COMPOSE_CMD build
    else
        echo "Building Docker images (this may take a few minutes)..."
        $COMPOSE_CMD build --no-cache
    fi

    # Start services
    echo "Starting services..."
    $COMPOSE_CMD up -d

    echo -e "${GREEN}✓ Services started${NC}"
}

# Wait for services to be ready
wait_for_services() {
    echo -e "${YELLOW}Waiting for services to be ready...${NC}"

    # Wait for PostgreSQL
    echo "Waiting for database..."
    for i in {1..30}; do
        if docker exec ms-abc-db pg_isready -U msabc -d ms_abc_db &> /dev/null; then
            echo -e "${GREEN}✓ Database is ready${NC}"
            break
        fi
        sleep 2
    done

    # Wait for backend
    echo "Waiting for backend API..."
    for i in {1..30}; do
        if curl -s http://localhost:${BACKEND_PORT:-3001}/health &> /dev/null; then
            echo -e "${GREEN}✓ Backend API is ready${NC}"
            break
        fi
        sleep 2
    done

    # Wait for frontend
    echo "Waiting for frontend..."
    for i in {1..30}; do
        if curl -s http://localhost:${FRONTEND_PORT:-3000} &> /dev/null; then
            echo -e "${GREEN}✓ Frontend is ready${NC}"
            break
        fi
        sleep 2
    done
}

# Run initial setup
run_initial_setup() {
    echo -e "${YELLOW}Running initial database setup...${NC}"

    # Run database seed
    docker exec ms-abc-backend sh -c "cd /app/packages/backend && npx prisma db seed" 2>/dev/null || true

    echo -e "${GREEN}✓ Initial setup complete${NC}"
}

# Print success message
print_success() {
    echo ""
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              Installation Complete! 🎉                        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "Access your application:"
    echo -e "  ${BLUE}Frontend:${NC} http://localhost:${FRONTEND_PORT:-3000}"
    echo -e "  ${BLUE}Backend API:${NC} http://localhost:${BACKEND_PORT:-3001}"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Go to Settings page and configure your retailer information"
    echo "  2. Go to Data Sync page to fetch initial data from MS ABC"
    echo "  3. (Optional) Add AI API keys to .env for advanced features"
    echo ""
    echo -e "${YELLOW}Useful Commands:${NC}"
    echo "  ./manage.sh status    - Check service status"
    echo "  ./manage.sh logs      - View logs"
    echo "  ./manage.sh stop      - Stop all services"
    echo "  ./manage.sh start     - Start all services"
    echo "  ./manage.sh restart   - Restart all services"
    echo "  ./manage.sh sync      - Manually trigger data sync"
    echo ""
}

# Main installation flow
main() {
    check_docker
    create_directories
    create_env_file
    check_existing_installation
    start_services
    wait_for_services
    run_initial_setup
    print_success
}

# Run main
main
