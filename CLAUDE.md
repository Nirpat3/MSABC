# CLAUDE.md - Agent Instructions

## Project Overview

MS ABC (Mississippi ABC Retailer Management System) — a monorepo managing inventory, deals, special orders, and PO forecasting. Uses npm workspaces with packages in `packages/backend` and `packages/frontend`.

## Tech Stack

- **Frontend:** React (Vite)
- **Backend:** Node.js + Express + Prisma ORM
- **Database:** PostgreSQL
- **Cache:** Redis
- **Infrastructure:** Docker Compose

## Quick Start (Docker — recommended)

```bash
bash run.sh
```

This single command checks prerequisites, creates `.env`, builds containers, starts services, waits for readiness, and seeds the database. Requires Docker and Docker Compose.

- Frontend: http://localhost:3000
- Backend API: http://localhost:3001
- Health check: http://localhost:3001/api/health

## Local Dev (without full Docker)

```bash
npm install
npm run dev:all     # starts postgres + redis via Docker, then runs backend & frontend
```

Or run individually:

```bash
npm run dev:backend
npm run dev:frontend
```

## Build

```bash
npm run build
```

## Tests

```bash
npm test                  # all workspace tests
npm run test:qa           # QA test suite
npm run test:qa:api       # API tests only
npm run test:qa:db        # Database tests only
npm run test:qa:frontend  # Frontend tests only
```

## Database

```bash
npm run db:migrate        # run Prisma migrations
npm run db:seed           # seed database
```

## Service Management

Use `./manage.sh` for container lifecycle:

```bash
./manage.sh start         # start containers
./manage.sh stop          # stop containers (data preserved)
./manage.sh status        # check service status
./manage.sh logs          # tail logs
./manage.sh backup        # create database backup
./manage.sh restore <file> # restore from backup
```
