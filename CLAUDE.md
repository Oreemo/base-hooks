# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository provides automated scripts to quickly spin up an OP Stack devnet with flashblocks capability, including automated deployment of Uniswap V3 and USDC contracts for testing purposes.

## Architecture

- **OP Stack Devnet**: Uses `flashbots/builder-playground` for L1/L2 setup
- **Flashblocks**: Integrates `flashbots/op-rbuilder` for flashblocks capability
- **Contract Deployment**: Automated USDC and Uniswap V3 deployment
- **Shell-based**: Pure shell scripts with Just task runner

## Common Commands

```bash
# Setup prerequisites (Docker, Go, Rust, Foundry)
just setup

# Start devnet with flashblocks and deploy contracts
just start

# Stop the devnet
just stop

# Clean up all data and processes
just clean

# Deploy contracts only (if devnet is running)
just deploy

# Show funded accounts with private keys
just accounts
```

## Key Components

- **justfile**: Task runner with all available commands
- **scripts/start-devnet.sh**: Main orchestration script
- **scripts/deploy-contracts.sh**: Contract deployment automation
- **scripts/show-accounts.sh**: Display funded accounts
- **scripts/cleanup.sh**: Complete cleanup of devnet state

## Network Configuration

- L2 RPC: `http://localhost:8545`
- L1 RPC: `http://localhost:8545` (builder-playground default)
- Chain ID: 901 (L2) / 900 (L1)
- Flashblocks endpoint: `ws://localhost:8080`

## Data Directories

- **data/**: Runtime data (PIDs, configs, contract addresses)
- **logs/**: Service logs (opstack.log, rbuilder.log)
- **artifacts/**: Generated artifacts from builder-playground

## Dependencies

- Docker (for OP Stack components)
- Go (for builder-playground)
- Rust/Cargo (for op-rbuilder)
- Foundry (cast, forge for contract interactions)
- bc (for balance calculations)