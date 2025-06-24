#!/bin/bash

set -e

echo "🧹 Cleaning up OP Stack devnet..."

# Stop all running containers
echo "Stopping Docker containers..."
docker stop $(docker ps -q --filter "name=op-stack" --filter "name=rbuilder" --filter "name=builder-playground") 2>/dev/null || true

# Remove containers
echo "Removing containers..."
docker rm $(docker ps -aq --filter "name=op-stack" --filter "name=rbuilder" --filter "name=builder-playground") 2>/dev/null || true

# Clean up volumes
echo "Cleaning up volumes..."
docker volume prune -f 2>/dev/null || true

# Kill any remaining processes
echo "Killing remaining processes..."
pkill -f "op-rbuilder" || true
pkill -f "builder-playground" || true
pkill -f "op-node" || true
pkill -f "op-geth" || true

# Remove data directories
echo "Removing data directories..."
rm -rf ./data/
rm -rf ./artifacts/
rm -rf ./l1-data/
rm -rf ./l2-data/
rm -rf ./.opstack/

# Clean up playground and reth data (as per op-rbuilder README)
echo "Cleaning up playground and reth data..."
rm -rf ~/.local/share/reth
sudo rm -rf ~/.playground 2>/dev/null || rm -rf ~/.playground

# Remove logs
echo "Removing logs..."
rm -rf ./logs/
rm -f *.log

echo "✅ Cleanup complete!"