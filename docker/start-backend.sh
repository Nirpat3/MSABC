#!/bin/sh
set -e

echo "Applying database schema..."
npx prisma db push --accept-data-loss 2>&1 || true

echo "Starting backend server..."
exec npx tsx src/index.ts
