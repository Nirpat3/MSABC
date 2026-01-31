#!/bin/bash

#############################################
# MS ABC Management Script
#############################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Backup configuration
BACKUP_DIR="${SCRIPT_DIR}/backups"

# Determine compose command
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

# Determine environment (dev or prod)
get_env_mode() {
    if [ -f .env ]; then
        APP_ENV=$(grep -E "^APP_ENV=" .env | cut -d'=' -f2)
        if [ "$APP_ENV" = "production" ]; then
            echo "production"
            return
        fi
    fi
    echo "development"
}

ENV_MODE=$(get_env_mode)

# Set environment-specific defaults
if [ "$ENV_MODE" = "production" ]; then
    BACKUP_RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-365}
    MAX_BACKUPS=${MAX_BACKUPS:-1000}
    BACKUP_AUTO_DELETE=${BACKUP_AUTO_DELETE:-false}
    ALLOW_DB_RESET=${ALLOW_DB_RESET:-false}
    COMPOSE_FILE="docker-compose.prod.yml"
    DB_CONTAINER="ms-abc-db-prod"
else
    BACKUP_RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}
    MAX_BACKUPS=${MAX_BACKUPS:-50}
    BACKUP_AUTO_DELETE=${BACKUP_AUTO_DELETE:-true}
    ALLOW_DB_RESET=${ALLOW_DB_RESET:-true}
    COMPOSE_FILE="docker-compose.yml"
    DB_CONTAINER="ms-abc-db"
fi

# Load environment
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

#############################################
# Helper Functions
#############################################

# Create a backup of the database
create_backup() {
    local BACKUP_TYPE="${1:-manual}"
    local SILENT="${2:-false}"

    mkdir -p "$BACKUP_DIR"

    # Check if database container is running
    if ! docker ps --format '{{.Names}}' | grep -q "$DB_CONTAINER"; then
        if [ "$SILENT" != "true" ]; then
            echo -e "${YELLOW}Database container not running, skipping backup${NC}"
        fi
        return 1
    fi

    local BACKUP_FILE="${BACKUP_DIR}/${BACKUP_TYPE}_$(date +%Y%m%d_%H%M%S).sql"

    if [ "$SILENT" != "true" ]; then
        echo -e "${YELLOW}Creating ${BACKUP_TYPE} backup...${NC}"
    fi

    if docker exec $DB_CONTAINER pg_dump -U ${POSTGRES_USER:-msabc} ${POSTGRES_DB:-ms_abc_db} > "$BACKUP_FILE" 2>/dev/null; then
        if [ -f "$BACKUP_FILE" ] && [ -s "$BACKUP_FILE" ]; then
            if [ "$SILENT" != "true" ]; then
                local SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
                echo -e "${GREEN}✓ Backup created: $BACKUP_FILE ($SIZE)${NC}"
            fi
            return 0
        fi
    fi

    # Backup failed, remove empty file
    rm -f "$BACKUP_FILE"
    if [ "$SILENT" != "true" ]; then
        echo -e "${RED}Failed to create backup${NC}"
    fi
    return 1
}

# Clean up old backups
cleanup_old_backups() {
    mkdir -p "$BACKUP_DIR"

    # In production, never auto-delete
    if [ "$BACKUP_AUTO_DELETE" != "true" ]; then
        return 0
    fi

    # Remove backups older than retention period
    find "$BACKUP_DIR" -name "*.sql" -type f -mtime +${BACKUP_RETENTION_DAYS} -delete 2>/dev/null

    # Keep only MAX_BACKUPS most recent backups
    local BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/*.sql 2>/dev/null | wc -l)
    if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
        ls -1t "$BACKUP_DIR"/*.sql | tail -n +$((MAX_BACKUPS + 1)) | xargs rm -f 2>/dev/null
    fi
}

# List available backups
list_backups() {
    echo -e "${BLUE}Available Backups:${NC}"
    echo ""
    if [ -d "$BACKUP_DIR" ] && [ "$(ls -A $BACKUP_DIR/*.sql 2>/dev/null)" ]; then
        echo "  File                                    Size       Date"
        echo "  ---------------------------------------- ---------- -------------------"
        ls -lht "$BACKUP_DIR"/*.sql 2>/dev/null | awk '{print "  " $9 " " $5 " " $6 " " $7 " " $8}' | head -20
        echo ""
        local TOTAL=$(ls -1 "$BACKUP_DIR"/*.sql 2>/dev/null | wc -l | tr -d ' ')
        echo -e "  Total: ${TOTAL} backups"
    else
        echo "  No backups found in $BACKUP_DIR"
    fi
    echo ""
}

case "$1" in
    start)
        echo -e "${BLUE}Environment: ${ENV_MODE}${NC}"
        echo -e "${YELLOW}Starting services...${NC}"

        # Create backup before start if database exists
        create_backup "startup" "true"

        $COMPOSE_CMD -f $COMPOSE_FILE up -d

        # Cleanup old backups (respects BACKUP_AUTO_DELETE)
        cleanup_old_backups

        echo -e "${GREEN}Services started${NC}"
        ;;

    stop)
        echo -e "${YELLOW}Stopping services...${NC}"
        $COMPOSE_CMD -f $COMPOSE_FILE down
        echo -e "${GREEN}Services stopped${NC}"
        ;;

    restart)
        echo -e "${YELLOW}Restarting services...${NC}"
        $COMPOSE_CMD -f $COMPOSE_FILE restart
        echo -e "${GREEN}Services restarted${NC}"
        ;;

    status)
        echo -e "${BLUE}Environment: ${ENV_MODE}${NC}"
        echo -e "${BLUE}Service Status:${NC}"
        $COMPOSE_CMD -f $COMPOSE_FILE ps
        ;;

    logs)
        if [ -z "$2" ]; then
            $COMPOSE_CMD logs -f --tail=100
        else
            $COMPOSE_CMD logs -f --tail=100 "$2"
        fi
        ;;

    sync)
        echo -e "${YELLOW}Triggering data sync...${NC}"
        curl -X POST http://localhost:${BACKEND_PORT:-3001}/api/sync/full
        echo ""
        echo -e "${GREEN}Sync triggered${NC}"
        ;;

    sync-prices)
        echo -e "${YELLOW}Syncing price list...${NC}"
        MONTH=${2:-$(date +%B)}
        YEAR=${3:-$(date +%Y)}
        curl -X POST http://localhost:${BACKEND_PORT:-3001}/api/sync/price-list \
            -H "Content-Type: application/json" \
            -d "{\"month\":\"$MONTH\",\"year\":$YEAR}"
        echo ""
        ;;

    sync-spas)
        echo -e "${YELLOW}Syncing SPAs...${NC}"
        MONTH=${2:-$(date +%B)}
        YEAR=${3:-$(date +%Y)}
        curl -X POST http://localhost:${BACKEND_PORT:-3001}/api/sync/spas \
            -H "Content-Type: application/json" \
            -d "{\"month\":\"$MONTH\",\"year\":$YEAR}"
        echo ""
        ;;

    forecast)
        echo -e "${YELLOW}Generating forecast...${NC}"
        curl -X POST http://localhost:${BACKEND_PORT:-3001}/api/forecasts/generate \
            -H "Content-Type: application/json" \
            -d "{}"
        echo ""
        echo -e "${GREEN}Forecast generated${NC}"
        ;;

    optimize-db)
        echo -e "${YELLOW}Running database optimization...${NC}"
        curl -X POST http://localhost:${BACKEND_PORT:-3001}/api/admin/optimize-db
        echo ""
        echo -e "${GREEN}Optimization triggered${NC}"
        ;;

    billing)
        echo -e "${BLUE}Current Billing Summary:${NC}"
        curl -s http://localhost:${BACKEND_PORT:-3001}/api/billing/summary | jq .
        ;;

    backup)
        create_backup "manual"
        ;;

    backup-list)
        list_backups
        ;;

    backup-cleanup)
        echo -e "${YELLOW}Cleaning up old backups...${NC}"
        cleanup_old_backups
        echo -e "${GREEN}Cleanup complete${NC}"
        list_backups
        ;;

    restore)
        if [ -z "$2" ]; then
            echo -e "${RED}Please specify backup file: ./manage.sh restore <backup_file>${NC}"
            echo ""
            list_backups
            exit 1
        fi

        # Check if file exists
        RESTORE_FILE="$2"
        if [ ! -f "$RESTORE_FILE" ]; then
            # Try looking in backups directory
            if [ -f "$BACKUP_DIR/$2" ]; then
                RESTORE_FILE="$BACKUP_DIR/$2"
            else
                echo -e "${RED}File not found: $2${NC}"
                exit 1
            fi
        fi

        echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║  Restore will OVERWRITE current database with backup data    ║${NC}"
        echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "Restore from: ${BLUE}$RESTORE_FILE${NC}"
        echo ""
        echo -e "${YELLOW}Create a backup of current data first? (y/n)${NC}"
        read -r backup_first

        if [ "$backup_first" = "y" ] || [ "$backup_first" = "Y" ]; then
            create_backup "pre_restore"
        fi

        echo -e "${YELLOW}Are you sure you want to restore? (type 'yes' to confirm)${NC}"
        read -r confirm

        if [ "$confirm" = "yes" ]; then
            echo -e "${YELLOW}Restoring from $RESTORE_FILE...${NC}"
            docker exec -i $DB_CONTAINER psql -U ${POSTGRES_USER:-msabc} ${POSTGRES_DB:-ms_abc_db} < "$RESTORE_FILE"
            echo -e "${GREEN}Restore complete${NC}"
        else
            echo -e "${GREEN}Restore cancelled${NC}"
        fi
        ;;

    shell)
        echo -e "${YELLOW}Opening shell in backend container...${NC}"
        if [ "$ENV_MODE" = "production" ]; then
            docker exec -it ms-abc-backend-prod sh
        else
            docker exec -it ms-abc-backend sh
        fi
        ;;

    db-shell)
        echo -e "${YELLOW}Opening database shell...${NC}"
        docker exec -it $DB_CONTAINER psql -U ${POSTGRES_USER:-msabc} ${POSTGRES_DB:-ms_abc_db}
        ;;

    update)
        echo -e "${BLUE}Environment: ${ENV_MODE}${NC}"
        echo -e "${YELLOW}Updating application...${NC}"

        # Create backup before update
        create_backup "pre_update"

        git pull
        $COMPOSE_CMD -f $COMPOSE_FILE build
        $COMPOSE_CMD -f $COMPOSE_FILE up -d
        echo -e "${GREEN}Update complete. Your data has been preserved.${NC}"
        ;;

    upgrade)
        echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║           SAFE UPGRADE WITH DATABASE MIGRATION               ║${NC}"
        echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${BLUE}Environment: ${ENV_MODE}${NC}"
        echo ""

        # Step 1: Create backup
        echo -e "${YELLOW}Step 1: Creating pre-upgrade backup...${NC}"
        if ! create_backup "pre_upgrade"; then
            echo -e "${RED}Warning: Could not create backup. Database may not be running.${NC}"
            echo -e "${YELLOW}Continue anyway? (y/n)${NC}"
            read -r continue_anyway
            if [ "$continue_anyway" != "y" ]; then
                echo -e "${GREEN}Upgrade cancelled${NC}"
                exit 0
            fi
        fi

        # Step 2: Pull latest code
        echo ""
        echo -e "${YELLOW}Step 2: Pulling latest code...${NC}"
        git fetch origin
        CURRENT_COMMIT=$(git rev-parse HEAD)
        git pull

        # Check if there are schema changes
        if git diff $CURRENT_COMMIT HEAD --name-only | grep -q "prisma/schema.prisma"; then
            echo -e "${YELLOW}Schema changes detected!${NC}"
            SCHEMA_CHANGED=true
        else
            SCHEMA_CHANGED=false
        fi

        # Step 3: Install dependencies
        echo ""
        echo -e "${YELLOW}Step 3: Installing dependencies...${NC}"
        npm install

        # Step 4: Run database migrations
        echo ""
        echo -e "${YELLOW}Step 4: Running database migrations...${NC}"
        echo -e "${BLUE}This will safely apply any new columns with default values${NC}"

        # Ensure database is running
        $COMPOSE_CMD -f $COMPOSE_FILE up -d postgres redis
        sleep 3

        # Run Prisma migrations
        cd packages/backend
        npx prisma migrate deploy
        MIGRATE_STATUS=$?
        cd ../..

        if [ $MIGRATE_STATUS -ne 0 ]; then
            echo -e "${RED}Migration failed!${NC}"
            echo -e "${YELLOW}Your backup is available at: $BACKUP_DIR${NC}"
            echo -e "${YELLOW}You can restore with: ./manage.sh restore <backup_file>${NC}"
            exit 1
        fi

        echo -e "${GREEN}✓ Migrations applied successfully${NC}"

        # Step 5: Rebuild and restart containers
        echo ""
        echo -e "${YELLOW}Step 5: Rebuilding containers...${NC}"
        $COMPOSE_CMD -f $COMPOSE_FILE build

        echo ""
        echo -e "${YELLOW}Step 6: Restarting services...${NC}"
        $COMPOSE_CMD -f $COMPOSE_FILE up -d

        echo ""
        echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                    UPGRADE COMPLETE!                         ║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${BLUE}Summary:${NC}"
        echo "  - Pre-upgrade backup created"
        echo "  - Code updated to latest version"
        echo "  - Database migrations applied"
        echo "  - Containers rebuilt and restarted"
        echo ""
        echo -e "${BLUE}Your data has been preserved!${NC}"
        ;;

    set-env)
        if [ -z "$2" ]; then
            echo -e "${RED}Usage: ./manage.sh set-env <development|production>${NC}"
            exit 1
        fi

        if [ "$2" = "development" ] || [ "$2" = "dev" ]; then
            echo -e "${YELLOW}Switching to DEVELOPMENT environment...${NC}"
            if [ -f .env.development ]; then
                cp .env.development .env
                echo -e "${GREEN}✓ Environment set to development${NC}"
            else
                echo -e "${RED}.env.development not found${NC}"
                exit 1
            fi
        elif [ "$2" = "production" ] || [ "$2" = "prod" ]; then
            echo -e "${YELLOW}Switching to PRODUCTION environment...${NC}"
            if [ -f .env.production ]; then
                cp .env.production .env
                echo -e "${GREEN}✓ Environment set to production${NC}"
                echo -e "${RED}IMPORTANT: Edit .env and set secure passwords!${NC}"
            else
                echo -e "${RED}.env.production not found${NC}"
                exit 1
            fi
        else
            echo -e "${RED}Invalid environment. Use 'development' or 'production'${NC}"
            exit 1
        fi
        ;;

    reset)
        # Block reset in production unless explicitly allowed
        if [ "$ENV_MODE" = "production" ] && [ "$ALLOW_DB_RESET" != "true" ]; then
            echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${RED}║              RESET BLOCKED IN PRODUCTION                     ║${NC}"
            echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
            echo ""
            echo -e "${YELLOW}Database reset is disabled in production to protect your data.${NC}"
            echo ""
            echo "If you really need to reset, you have two options:"
            echo "  1. Set ALLOW_DB_RESET=true in .env (not recommended)"
            echo "  2. Switch to development: ./manage.sh set-env development"
            echo ""
            exit 1
        fi

        echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║                    ⚠️  WARNING ⚠️                              ║${NC}"
        echo -e "${RED}║  This will DELETE ALL DATA including:                        ║${NC}"
        echo -e "${RED}║  - Your business profile                                     ║${NC}"
        echo -e "${RED}║  - All synced products and SPAs                              ║${NC}"
        echo -e "${RED}║  - Purchase orders and forecasts                             ║${NC}"
        echo -e "${RED}║  - All historical data                                       ║${NC}"
        echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${BLUE}Environment: ${ENV_MODE}${NC}"
        echo ""
        echo -e "${YELLOW}Are you sure you want to reset everything? (type 'yes' to confirm)${NC}"
        read -r response
        if [ "$response" = "yes" ]; then
            echo -e "${YELLOW}Creating final backup before reset...${NC}"
            create_backup "pre_reset"

            echo -e "${YELLOW}Stopping and removing all containers and volumes...${NC}"
            $COMPOSE_CMD -f $COMPOSE_FILE down -v
            echo -e "${GREEN}Reset complete. Run ./install.sh to start fresh.${NC}"
        else
            echo -e "${GREEN}Reset cancelled. Your data is safe.${NC}"
        fi
        ;;

    export-profile)
        echo -e "${YELLOW}Exporting business profile...${NC}"
        mkdir -p backups
        EXPORT_FILE="backups/profile_export_$(date +%Y%m%d_%H%M%S).json"
        curl -s http://localhost:${BACKEND_PORT:-3001}/api/profile > "$EXPORT_FILE"
        if [ -f "$EXPORT_FILE" ] && [ -s "$EXPORT_FILE" ]; then
            # Check if the response is an error
            if grep -q "requiresSetup" "$EXPORT_FILE"; then
                echo -e "${YELLOW}No profile exists to export.${NC}"
                rm "$EXPORT_FILE"
            else
                echo -e "${GREEN}✓ Profile exported: $EXPORT_FILE${NC}"
            fi
        else
            echo -e "${RED}Failed to export profile. Is the backend running?${NC}"
        fi
        ;;

    import-profile)
        if [ -z "$2" ]; then
            echo -e "${RED}Please specify profile file: ./manage.sh import-profile <file.json>${NC}"
            echo ""
            echo "Available exports:"
            ls -la backups/profile_export_*.json 2>/dev/null || echo "  No profile exports found in backups/"
            exit 1
        fi
        if [ ! -f "$2" ]; then
            echo -e "${RED}File not found: $2${NC}"
            exit 1
        fi
        echo -e "${YELLOW}Importing business profile from $2...${NC}"
        curl -X POST http://localhost:${BACKEND_PORT:-3001}/api/profile/import \
            -H "Content-Type: application/json" \
            -d @"$2"
        echo ""
        echo -e "${GREEN}Profile import complete${NC}"
        ;;

    *)
        echo "MS ABC Management Script"
        echo ""
        echo -e "${BLUE}Current Environment: ${ENV_MODE}${NC}"
        echo ""
        echo "Usage: ./manage.sh <command> [options]"
        echo ""
        echo -e "${GREEN}Environment Management:${NC}"
        echo "  set-env <dev|prod>  Switch between development and production"
        echo "  upgrade             Safe upgrade with database migration"
        echo "  update              Quick update (pull, build, restart)"
        echo ""
        echo -e "${GREEN}Service Management:${NC}"
        echo "  start           Start all services"
        echo "  stop            Stop all services (data preserved)"
        echo "  restart         Restart all services"
        echo "  status          Show service status"
        echo "  logs [service]  View logs (optionally for specific service)"
        echo ""
        echo -e "${GREEN}Data Sync:${NC}"
        echo "  sync            Trigger full data sync"
        echo "  sync-prices [month] [year]  Sync price list"
        echo "  sync-spas [month] [year]    Sync SPAs"
        echo "  forecast        Generate PO forecast"
        echo ""
        echo -e "${GREEN}Backup & Restore:${NC}"
        echo "  backup          Create database backup"
        echo "  backup-list     List all available backups"
        echo "  backup-cleanup  Remove old backups (keeps last $MAX_BACKUPS)"
        echo "  restore <file>  Restore from backup (with confirmation)"
        echo "  export-profile  Export business profile to JSON"
        echo "  import-profile <file>  Import business profile from JSON"
        echo ""
        echo -e "${GREEN}Database & Admin:${NC}"
        echo "  optimize-db     Run AI database optimization"
        echo "  billing         Show billing summary"
        echo "  shell           Open shell in backend container"
        echo "  db-shell        Open PostgreSQL shell"
        echo ""
        echo -e "${RED}Destructive (requires confirmation):${NC}"
        echo "  reset           DELETE ALL DATA (blocked in production)"
        echo ""
        echo -e "${BLUE}Environment Differences:${NC}"
        echo "  Development: Auto-delete old backups, allow reset"
        echo "  Production:  Keep all backups, block reset, daily auto-backup"
        ;;
esac
