#!/bin/bash

echo "🧹 Cleaning up..."
# Kill any process on port 3001
lsof -ti:3001 | xargs kill -9 2>/dev/null || echo "No process on port 3001"

# Clear caches
rm -rf node_modules/.cache
rm -rf build
rm -rf .cache

echo "✨ Starting development server..."
echo "⚠️  Please do a hard refresh in your browser after the server starts:"
echo "   - Mac: Cmd + Shift + R"
echo "   - Windows/Linux: Ctrl + Shift + R"
echo ""

PORT=3001 npm start


