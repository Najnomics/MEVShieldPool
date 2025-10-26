#!/bin/bash

echo "🔧 Fixing dependencies and starting dev server..."

cd /Users/najnomics/october/MEVShieldPool/frontend

# Kill any process on port 3001
lsof -ti:3001 | xargs kill -9 2>/dev/null || true

# Clear caches
rm -rf node_modules/.cache build .cache

# Increase file limit
ulimit -n 10240

# Install with legacy peer deps (to handle TypeScript version conflict)
echo "📦 Installing dependencies..."
npm install ajv --legacy-peer-deps
npm install --legacy-peer-deps

# Start the server
echo "🚀 Starting dev server..."
PORT=3001 npm start

