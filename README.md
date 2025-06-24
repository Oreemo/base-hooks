# Base Hooks - OP Stack Devnet with Flashblocks

Quickly spin up an OP Stack devnet with flashblocks capability and pre-deployed Uniswap V3 + USDC contracts.

## Features

- 🚀 **One-command setup**: Complete OP Stack L1/L2 devnet with flashblocks
- ⚡ **Flashblocks enabled**: Uses op-rbuilder for flashblocks capability
- 🦄 **Uniswap V3 ready**: Pre-deployed Uniswap V3 Factory and Position Manager
- 💰 **USDC included**: Mock USDC contract for testing
- 🔑 **Funded accounts**: 10 pre-funded accounts with private keys
- 🧹 **Easy cleanup**: One command to clean everything

## Quick Start

1. **Setup prerequisites**:
   ```bash
   just setup
   ```

2. **Start the devnet**:
   ```bash
   just start
   ```

3. **View funded accounts**:
   ```bash
   just accounts
   ```

4. **Stop when done**:
   ```bash
   just stop
   ```

## Available Commands

- `just setup` - Install prerequisites (Docker, Go, Rust, Foundry)
- `just start` - Start devnet with flashblocks and deploy contracts
- `just stop` - Stop the devnet
- `just clean` - Clean up all data and processes
- `just deploy` - Deploy contracts only (if devnet is running)
- `just accounts` - Show funded accounts with private keys

## Network Details

- **L2 RPC**: `http://localhost:8545`
- **Chain ID**: 901 (L2) / 900 (L1)  
- **Flashblocks**: `ws://localhost:8080`

## What Gets Deployed

- Mock USDC contract (6 decimals)
- Uniswap V3 Factory
- Uniswap V3 Position Manager
- Pre-funded accounts with ETH and USDC

## Requirements

- Docker
- Git
- Internet connection (for downloading dependencies)

The setup script will automatically install:
- Go (for builder-playground)
- Rust (for op-rbuilder)
- Foundry (for contract interactions)

## Troubleshooting

- Check logs in `logs/` directory
- Use `just clean` to reset everything
- Ensure Docker is running before starting

## License

MIT