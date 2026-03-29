#!/bin/bash
echo "**************************************************"
echo " Setting up Node.js Counter Service Environment"
echo "**************************************************"

echo "*** Checking Node.js and npm versions..."

node --version
npm --version

echo "*** Installing project dependencies..."
npm install

echo "*** Setting up development environment..."
export NODE_ENV=development
export PORT=8000

echo "**************************************************"
echo " Node.js Counter Service Environment Setup Complete"
echo "**************************************************"
echo ""
echo "Use 'npm start' to run the service"
echo "Use 'npm run dev' for development with auto-reload"
echo "Use 'npm test' to run tests"
echo ""