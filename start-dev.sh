#!/bin/bash
cd packages/backend && npx tsx src/index.ts &
sleep 2
cd packages/frontend && npm run dev
