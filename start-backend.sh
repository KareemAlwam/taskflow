#!/bin/bash

echo "🚀 Starting TaskFlow Backend..."
echo ""

# Navigate to backend directory
cd "$(dirname "$0")/backend"

# Check if .env exists
if [ ! -f .env ]; then
    echo "⚠️  .env file not found!"
    echo "   Please create one based on .env.example"
    exit 1
fi

if [ ! -d node_modules ]; then
    echo "📦 Installing backend dependencies..."
    npm install
fi

echo "📦 Starting backend using the configured MongoDB connection"
echo ""
npm start
