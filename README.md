# MS ABC Retailer Management System

A comprehensive management system for Mississippi ABC (Alcoholic Beverage Control) retailers. Automatically fetches product data, tracks deals/SPAs, manages special orders, and generates AI-enhanced PO forecasts.

## Features

### Phase 1: Data Foundation
- **Product Catalog**: Full product database with 3,900+ stocked items and 14,300+ special order items
- **Automated Data Sync**: Fetches and parses price lists and SPAs from MS ABC website
- **Price History Tracking**: Monitor price changes over time

### Phase 2: Deal Intelligence
- **SPA Tracking**: Monitor all active Special Pricing Allowances
- **Deal Alerts**: Get notified about new deals, expiring deals, and price drops
- **Profitability Analysis**: Score deals based on savings potential
- **Recommendations**: Smart suggestions for best buying opportunities

### Phase 3: Special Order Management
- **Customer Tracking**: Manage special order customers
- **Order Consolidation**: Group multiple customer requests for the same product
- **PDF Form Generation**: Auto-fill ABC Sales Order Forms
- **Status Tracking**: Track orders from request to fulfillment

### Phase 4: PO Forecasting
- **Historical Analysis**: Analyze past orders to predict future needs
- **AI Enhancement**: Weekly AI-powered forecast insights and recommendations
- **SPA Integration**: Factor in upcoming deals for optimal ordering
- **Order Conversion**: Convert approved forecasts directly to orders

### Additional Features
- **Billing Dashboard**: Track AI token usage and costs by module
- **Database Optimization**: AI-powered automatic performance tuning
- **Configurable Sync**: Set intervals (minutes, hourly, daily, weekly) with retry logic

---

## Table of Contents

1. [Prerequisites - Installing Docker](#prerequisites---installing-docker)
   - [Windows](#windows)
   - [macOS](#macos)
   - [Linux](#linux)
2. [Installation & Running the Application](#installation--running-the-application)
3. [Pulling from Docker Hub](#pulling-from-docker-hub)
4. [Publishing to Docker Hub](#publishing-to-docker-hub)
5. [Management Commands](#management-commands)
6. [Configuration](#configuration)
7. [API Documentation](#api-documentation)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites - Installing Docker

### Windows

#### System Requirements
- Windows 10 64-bit: Pro, Enterprise, or Education (Build 19041 or higher)
- Windows 11 64-bit
- WSL 2 feature enabled

#### Installation Steps

1. **Download Docker Desktop**
   - Go to: https://www.docker.com/products/docker-desktop/
   - Click **"Download for Windows"**

2. **Install Docker Desktop**
   - Double-click `Docker Desktop Installer.exe`
   - Follow the installation wizard
   - When prompted, ensure **"Use WSL 2 instead of Hyper-V"** is selected

3. **Start Docker Desktop**
   - Search for "Docker Desktop" in Start menu
   - Click to open
   - Wait for Docker to start (whale icon in system tray will stop animating)

4. **Verify Installation**

   Open PowerShell or Command Prompt and run:
   ```powershell
   docker --version
   docker compose version
   ```

#### Enable WSL 2 (if not already enabled)
```powershell
# Run PowerShell as Administrator
wsl --install

# Restart your computer after installation
```

---

### macOS

#### System Requirements
- macOS 11 (Big Sur) or newer
- Apple Silicon (M1/M2/M3) or Intel processor
- At least 4GB RAM

#### Installation Steps

**Option 1: Direct Download (Recommended)**

1. **Download Docker Desktop**
   - Go to: https://www.docker.com/products/docker-desktop/
   - Click **"Download for Mac"**
   - Choose **Apple Silicon** (M1/M2/M3) or **Intel chip** based on your Mac

   > **How to check your Mac type:** Click Apple menu () → About This Mac → Look for "Chip" (Apple Silicon) or "Processor" (Intel)

2. **Install Docker Desktop**
   - Open the downloaded `.dmg` file
   - Drag the Docker icon to the Applications folder

3. **Start Docker Desktop**
   - Open Docker from Applications folder (or Spotlight search: Cmd+Space, type "Docker")
   - Click "Open" if you see a security warning
   - Wait for Docker to start (whale icon in menu bar will stop animating)

**Option 2: Using Homebrew**
```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Docker Desktop
brew install --cask docker

# Open Docker Desktop
open /Applications/Docker.app
```

4. **Verify Installation**
   ```bash
   docker --version
   docker compose version
   ```

---

### Linux

#### Ubuntu / Debian

```bash
# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install -y \
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

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add your user to docker group (to run without sudo)
sudo usermod -aG docker $USER

# Apply group changes (or log out and back in)
newgrp docker

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Verify installation
docker --version
docker compose version
```

#### Fedora / RHEL / CentOS

```bash
# Install dnf-plugins-core
sudo dnf -y install dnf-plugins-core

# Add Docker repository
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

# Install Docker
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker compose version
```

#### Arch Linux

```bash
# Install Docker
sudo pacman -S docker docker-compose

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker compose version
```

---

## Installation & Running the Application

### Method 1: One-Click Run (Fastest - No Docker Required)

```bash
# Clone the repository
git clone https://github.com/yourusername/ms-abc-app.git
cd ms-abc-app

# Run the app (installs everything automatically)
./run.sh
```

This single command will:
- ✅ Check prerequisites (Node.js >= 18, PostgreSQL)
- ✅ Start PostgreSQL if not running
- ✅ Create database and user automatically
- ✅ Generate `.env` configuration
- ✅ Install all npm dependencies
- ✅ Set up database schema and seed data
- ✅ Start both backend (port 3001) and frontend (port 5000)

**Requirements:** Node.js >= 18 and PostgreSQL installed locally.

### Method 2: One-Click Docker Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/ms-abc-app.git
cd ms-abc-app

# Make install script executable
chmod +x install.sh

# Run the installer
./install.sh
```

The installer will:
- ✅ Check Docker prerequisites
- ✅ Create necessary directories (backups, logs, generated-forms)
- ✅ Generate environment configuration with secure passwords
- ✅ Build Docker images
- ✅ Start all services (PostgreSQL, Redis, Backend, Frontend, DB Optimizer)
- ✅ Run database seeding

### Method 3: Manual Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/ms-abc-app.git
cd ms-abc-app

# Create required directories
mkdir -p backups logs generated-forms

# Create environment file
cp .env.example .env

# Edit configuration (set secure passwords!)
nano .env  # or use any text editor

# Build and start services
docker compose up -d --build

# Wait for services to be healthy (check status)
docker compose ps

# Run database seed (first time only)
docker exec ms-abc-backend sh -c "npx prisma db seed"
```

### Access the Application

Once running, access the application at:

| Service | URL |
|---------|-----|
| **Frontend (Web App)** | http://localhost:3000 |
| **Backend API** | http://localhost:3001 |
| **API Health Check** | http://localhost:3001/health |

---

## Pulling from Docker Hub

If images are published to Docker Hub, you can run the application without building from source:

### Quick Start (3 Commands)

```bash
# 1. Create a project directory and download files
mkdir ms-abc-app && cd ms-abc-app
curl -O https://raw.githubusercontent.com/yourusername/ms-abc-app/main/docker-compose.hub.yml
curl -O https://raw.githubusercontent.com/yourusername/ms-abc-app/main/.env.example

# 2. Configure environment
cp .env.example .env
nano .env  # Edit: set POSTGRES_PASSWORD and optionally add AI API keys

# 3. Create directories and start
mkdir -p backups logs generated-forms
docker compose -f docker-compose.hub.yml up -d
```

### Manual Pull Commands

```bash
# Pull images (replace 'yourusername' with actual Docker Hub username)
docker pull yourusername/ms-abc-backend:latest
docker pull yourusername/ms-abc-frontend:latest

# Or pull a specific version
docker pull yourusername/ms-abc-backend:1.0.0
docker pull yourusername/ms-abc-frontend:1.0.0
```

---

## Publishing to Docker Hub

To make your images available for others to pull:

### Prerequisites

1. Create a Docker Hub account at https://hub.docker.com
2. Have Docker running on your machine

### Using the Publish Script (Easiest)

```bash
# Make script executable
chmod +x publish.sh

# Publish with your Docker Hub username
DOCKER_USERNAME=your_dockerhub_username ./publish.sh

# Or publish a specific version
DOCKER_USERNAME=your_dockerhub_username VERSION=1.0.0 ./publish.sh
```

### Manual Publishing

```bash
# 1. Login to Docker Hub
docker login

# 2. Build images
docker compose build

# 3. Tag images (replace 'yourusername' with your Docker Hub username)
docker tag ms-abc-app-backend:latest yourusername/ms-abc-backend:latest
docker tag ms-abc-app-frontend:latest yourusername/ms-abc-frontend:latest

# 4. Push images
docker push yourusername/ms-abc-backend:latest
docker push yourusername/ms-abc-frontend:latest
```

### GitHub Container Registry (Alternative)

If you push this repo to GitHub, the included GitHub Actions workflow will automatically build and publish images:

```bash
# Pull from GitHub Container Registry
docker pull ghcr.io/yourusername/ms-abc-app-backend:main
docker pull ghcr.io/yourusername/ms-abc-app-frontend:main
```

---

## Management Commands

Use the management script for common operations:

```bash
# Make script executable (first time only)
chmod +x manage.sh
```

### Service Management
```bash
./manage.sh start          # Start all services
./manage.sh stop           # Stop all services
./manage.sh restart        # Restart all services
./manage.sh status         # Check service status
./manage.sh update         # Pull latest changes and restart
```

### Viewing Logs
```bash
./manage.sh logs           # View all logs (follow mode)
./manage.sh logs backend   # View backend logs only
./manage.sh logs frontend  # View frontend logs only
./manage.sh logs postgres  # View database logs
```

### Data Sync
```bash
./manage.sh sync                    # Trigger full data sync
./manage.sh sync-prices             # Sync price list for current month
./manage.sh sync-prices January 2026 # Sync specific month
./manage.sh sync-spas               # Sync SPAs for current month
```

### Database Operations
```bash
./manage.sh backup              # Create database backup
./manage.sh restore backup.sql  # Restore from backup file
./manage.sh db-shell            # Open PostgreSQL interactive shell
./manage.sh optimize-db         # Run AI database optimization
```

### Forecasting & Billing
```bash
./manage.sh forecast       # Generate PO forecast
./manage.sh billing        # Show current billing summary
```

---

## Configuration

### Environment Variables

Edit the `.env` file to configure the application:

```bash
#############################################
# Database Configuration
#############################################
POSTGRES_USER=msabc
POSTGRES_PASSWORD=your_secure_password_here  # CHANGE THIS!
POSTGRES_DB=ms_abc_db
POSTGRES_PORT=5432

#############################################
# Application Ports
#############################################
FRONTEND_PORT=3000
BACKEND_PORT=3001
REDIS_PORT=6379

#############################################
# AI Configuration (Optional - for enhanced features)
#############################################
# For OpenAI
AI_PROVIDER=openai
OPENAI_API_KEY=sk-your-openai-api-key

# Or for Anthropic Claude
# AI_PROVIDER=anthropic
# ANTHROPIC_API_KEY=your-anthropic-api-key

#############################################
# Data Sync Configuration
#############################################
SYNC_ENABLED=true
SYNC_INTERVAL=daily          # Options: minutes, hourly, daily, weekly
SYNC_INTERVAL_MINUTES=60     # Used when SYNC_INTERVAL=minutes
SYNC_RETRY_ATTEMPTS=3
SYNC_RETRY_DELAY_MS=60000    # 1 minute
SYNC_RETRY_BACKOFF_MULTIPLIER=2

#############################################
# Database Optimization
#############################################
DB_OPTIMIZATION_INTERVAL_HOURS=24
AI_QUERY_OPTIMIZATION=true

#############################################
# Billing & Token Tracking
#############################################
TRACK_TOKEN_USAGE=true
MONTHLY_TOKEN_BUDGET=0       # 0 = unlimited
```

---

## API Documentation

### Products
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/products` | List products with filtering |
| GET | `/api/products/:id` | Get product details |
| GET | `/api/products/meta/categories` | Get category list |

### Deals & SPAs
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/deals/summary` | Dashboard summary |
| GET | `/api/deals/spas` | List active SPAs |
| GET | `/api/deals/recommended` | Get deal recommendations |
| GET | `/api/deals/alerts` | Get deal alerts |

### Special Orders
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/special-orders` | List by status |
| POST | `/api/special-orders` | Create request |
| POST | `/api/special-orders/consolidate` | Consolidate orders |
| POST | `/api/special-orders/consolidated/:id/generate-pdf` | Generate form |

### Forecasts
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/forecasts` | List forecasts |
| POST | `/api/forecasts/generate` | Generate new forecast |
| POST | `/api/forecasts/:id/approve` | Approve forecast |
| POST | `/api/forecasts/:id/convert-to-order` | Convert to order |

### Billing
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/billing/summary` | Get billing summary |
| GET | `/api/billing/usage` | Token usage history |
| GET | `/api/billing/trend` | Daily usage trend |
| GET | `/api/billing/operations` | Cost by operation |

### Admin
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/admin/sync/schedules` | Get sync schedules |
| POST | `/api/admin/sync/trigger/:type` | Trigger manual sync |
| PUT | `/api/admin/sync/schedule/:type` | Update schedule |
| POST | `/api/admin/optimize-db` | Run DB optimization |

---

## Troubleshooting

### Docker Not Starting

**Windows:**
```powershell
# Ensure WSL 2 is installed
wsl --install

# Enable virtualization in BIOS if needed
# Restart Docker Desktop
```

**macOS:**
```bash
# Ensure enough disk space (Docker needs ~2GB)
# Restart Docker
killall Docker && open /Applications/Docker.app
```

**Linux:**
```bash
# Check Docker service status
sudo systemctl status docker

# Start if not running
sudo systemctl start docker

# Check logs for errors
sudo journalctl -u docker
```

### Permission Denied Errors

```bash
# Add your user to docker group
sudo usermod -aG docker $USER

# Apply changes (or log out and back in)
newgrp docker
```

### Port Already in Use

```bash
# Find what's using the port
lsof -i :3000  # or :3001, :5432, :6379

# Kill the process
kill -9 <PID>

# Or change ports in .env file
FRONTEND_PORT=8080
BACKEND_PORT=8081
```

### Container Won't Start

```bash
# Check container logs
docker compose logs backend
docker compose logs frontend
docker compose logs postgres

# Rebuild from scratch
docker compose down -v
docker compose build --no-cache
docker compose up -d
```

### Database Connection Issues

```bash
# Check if database is healthy
docker compose ps

# View database logs
docker compose logs postgres

# Reset database completely
docker compose down -v
docker compose up -d
# Wait for containers, then re-seed
docker exec ms-abc-backend sh -c "npx prisma db seed"
```

### Reset Everything

```bash
# Stop and remove all containers and volumes
docker compose down -v

# Remove built images
docker compose down -v --rmi all

# Start fresh
./install.sh
```

### Check System Resources

```bash
# View Docker resource usage
docker stats

# If containers are slow, allocate more resources:
# Docker Desktop → Settings → Resources → Increase Memory/CPU
```

---

## Tech Stack

- **Frontend**: React 18 + Vite + TailwindCSS + React Query
- **Backend**: Node.js + Express + TypeScript
- **Database**: PostgreSQL 16 + Prisma ORM
- **Cache**: Redis 7
- **AI**: OpenAI / Anthropic Claude (optional)
- **Containerization**: Docker + Docker Compose

## Data Sources

Data is synced from the Mississippi Department of Revenue ABC website:
- Monthly Price Lists
- SPAs (Special Pricing Allowances)
- ABC Sales Order Forms

## License

MIT License - see LICENSE file for details.

## Support

For issues and feature requests, please open an issue on GitHub.
