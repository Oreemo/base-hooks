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

# Show funded accounts
accounts:
    @echo "💰 Funded accounts:"
    @bash scripts/show-accounts.sh

# Deploy contracts only (assumes devnet is running)
deploy:
    @echo "📦 Deploying contracts..."
    @bash scripts/deploy-contracts.sh

# Deploy individual components
deploy-simple-token:
    @echo "📦 Deploying SimpleToken..."
    @bash scripts/deploy-simple-token.sh

deploy-uniswapv2:
    @echo "🦄 Deploying Uniswap V2..."
    @bash scripts/deploy-uniswapv2.sh

deploy-base-hooks:
    @echo "🎯 Deploying HooksPerpetualAuction..."
    @bash scripts/deploy-base-hooks.sh

deploy-base-hooks-deterministic:
    @echo "🎯 Deploying HooksPerpetualAuction (deterministic)..."
    @DETERMINISTIC=true bash scripts/deploy-base-hooks.sh

deploy-arb-hook:
    @echo "🎯 Deploying UniswapV2ArbHook..."
    @bash scripts/deploy-arb-hook.sh

compute-hook-address:
    @echo "🔍 Computing deterministic hook address..."
    @bash scripts/compute-hook-address.sh

debug-collision:
    @echo "🔍 Debugging address collision..."
    @bash scripts/debug-address-collision.sh

# Setup prerequisites
setup:
    @echo "⚙️  Setting up prerequisites..."
    @bash scripts/setup.sh