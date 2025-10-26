#!/bin/bash

echo "🧹 Cleaning development environment..."

# Kill any process on port 3001
lsof -ti:3001 | xargs kill -9 2>/dev/null || true

# Remove all cache directories
rm -rf node_modules/.cache
rm -rf build
rm -rf .cache
rm -rf public/service-worker.js
rm -rf public/sw.js

# Increase file descriptor limit (for macOS)
ulimit -n 10240

echo "✨ Starting clean development server..."
echo ""
echo "⚠️  IMPORTANT: After server starts, do the following in your browser:"
echo "   1. Open DevTools (F12 or Cmd+Option+I)"
echo "   2. Go to Application tab → Service Workers"
echo "   3. Click 'Unregister' for localhost:3001"
echo "   4. Go to Application tab → Storage → Clear site data"
echo "   5. Do a hard refresh: Cmd+Shift+R (Mac) or Ctrl+Shift+R (Win)"
echo ""

PORT=3001 npm start


