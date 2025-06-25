# OP Stack Devnet with Flashblocks
# Usage: just <command>

# Default recipe - show available commands
default:
    @just --list

# Clean up all devnet components and data
clean:
    @echo "🧹 Cleaning up devnet..."
    @bash scripts/cleanup.sh

# Start the full devnet with flashblocks and deploy contracts
start: clean start-devnet deploy

# Start just the devnet (no contract deployment)
start-devnet: clean
    @echo "🚀 Starting OP Stack devnet with flashblocks..."
    @bash scripts/start-devnet.sh

# Stop the devnet
stop:
    @echo "🛑 Stopping devnet..."
    @bash scripts/stop-devnet.sh

# Deploy contracts only (assumes devnet is running)
deploy:
    @echo "📦 Deploying contracts..."
    @bash scripts/deploy-contracts.sh

# Show funded accounts
accounts:
    @echo "💰 Funded accounts:"
    @bash scripts/show-accounts.sh

# Deploy HooksPerpetualAuction contract
deploy-hooks:
    @echo "🎯 Deploying HooksPerpetualAuction..."
    @bash scripts/deploy-hooks.sh

# Setup prerequisites
setup:
    @echo "⚙️  Setting up prerequisites..."
    @bash scripts/setup.sh