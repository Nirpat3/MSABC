# MS ABC Retailer Management System

## Overview
A comprehensive management system for Mississippi ABC (Alcoholic Beverage Control) retailers. This monorepo contains both frontend and backend applications for managing inventory, deals, special orders, and PO forecasting.

## Project Architecture

```
ms-abc-app/
├── packages/
│   ├── backend/        # Express + TypeScript API
│   │   ├── src/        # Source code
│   │   └── prisma/     # Database schema and migrations
│   └── frontend/       # React + Vite + TailwindCSS
│       └── src/        # React components and pages
├── start-dev.sh        # Development startup script
└── package.json        # Root monorepo config
```

## Tech Stack
- **Frontend**: React 18, Vite, TailwindCSS, React Query, React Router
- **Backend**: Node.js, Express, TypeScript, Prisma ORM
- **Database**: PostgreSQL (Replit built-in)

## Development
- Frontend runs on port 5000 (exposed to web)
- Backend runs on port 3001 (internal API)
- Frontend proxies `/api/*` requests to backend

## Key API Endpoints
- `GET /api/health` - Health check
- `GET /api/products` - List products with filtering
- `GET /api/deals/summary` - Dashboard deal summary
- `GET /api/deals/spas` - Active SPAs
- `GET /api/special-orders` - Special orders list
- `GET /api/forecasts` - PO forecasts

## Database
Using Replit's built-in PostgreSQL database with Prisma ORM.
Schema includes: Product, PriceHistory, SPA, ProductSPA, SpecialOrder, Forecast, SyncLog, TokenUsage

## Recent Changes
- Initial setup: Created full-stack application from Docker-based GitHub import
- Set up backend with Express, Prisma, and TypeScript
- Set up frontend with React, Vite, and TailwindCSS
- Configured database schema and seeded sample data
- Configured Vite to allow all hosts for Replit proxy compatibility
