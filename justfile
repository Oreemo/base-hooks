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

# Build and restart op-rbuilder
restart-rbuilder:
    @echo "🔄 Building and restarting op-rbuilder..."
    @bash scripts/restart-rbuilder.sh

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

# Configuration commands
configure:
    @echo "⚙️  Configuring all contracts..."
    @bash scripts/configure-contracts.sh

configure-hooks:
    @echo "⚙️  Configuring HooksPerpetualAuction..."
    @bash scripts/configure-hooks.sh

configure-arb-hook:
    @echo "⚙️  Configuring UniswapV2ArbHook..."
    @bash scripts/configure-arb-hook.sh

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

# Place a bid on the HooksPerpetualAuction for Uniswap V2 Swap events
place-bid:
    @echo "🎯 Placing bid on HooksPerpetualAuction..."
    @bash scripts/place-bid-simple.sh

# Update Rust bindings from contracts
update-bindings:
    @echo "🦀 Updating Rust bindings..."
    @cd contracts/base-hooks && forge bind --bindings-path ../../op-rbuilder/crates/base-hooks-bindings --crate-name base-hooks-bindings --overwrite
    @echo "✅ Bindings updated successfully!"

# Trigger a Uniswap V2 swap to generate Swap events
trigger-swap:
    @echo "🔄 Triggering Uniswap V2 swap..."
    @bash scripts/trigger-swap.sh