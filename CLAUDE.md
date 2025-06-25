# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository provides automated scripts to quickly spin up an OP Stack devnet with flashblocks capability, including automated deployment of ERC20 test tokens, Uniswap V2 contracts, and HooksPerpetualAuction for testing purposes.

## Architecture

- **OP Stack Devnet**: Uses `flashbots/builder-playground` for L1/L2 setup
- **Flashblocks**: Integrates `flashbots/op-rbuilder` for flashblocks capability
- **Contract Deployment**: Automated ERC20 token, Uniswap V2, and HooksPerpetualAuction deployment with liquidity provision
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

# Deploy HooksPerpetualAuction contract
just deploy-hooks

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

- **L1 RPC**: `http://localhost:8545` (builder-playground default)
- **L2 RPC**: `http://localhost:8546` (builder-playground L2)
- **Builder RPC**: `http://localhost:2222` (op-rbuilder)
- **Chain ID**: 901 (L2) / 900 (L1)
- **Flashblocks endpoint**: `ws://localhost:8080`
- **System WETH**: `0x4200000000000000000000000000000000000006` (OP Stack predeploy)

## Data Directories

- **data/**: Runtime data (PIDs, configs, contract addresses)
- **logs/**: Service logs (opstack.log, rbuilder.log)
- **artifacts/**: Generated artifacts from builder-playground

## Contract Structure

```
contracts/
├── simple-token/          # ERC20 token Foundry project
│   ├── src/SimpleToken.sol
│   ├── script/SimpleToken.s.sol
│   └── foundry.toml
├── uniswapv2/            # Uniswap V2 Foundry project
│   ├── src/UniswapV2Factory.sol  # Factory + Pair contracts
│   ├── script/UniswapV2.s.sol    # Deployment script
│   └── foundry.toml
└── base-hooks/           # HooksPerpetualAuction Foundry project
    ├── src/HooksPerpetualAuction.sol  # Perpetual auction system
    ├── script/HooksPerpetualAuction.s.sol  # Deployment script
    └── foundry.toml
```

## Deployed Contracts

- **SimpleToken**: ERC20 test token with 1B initial supply (18 decimals)
- **UniswapV2Factory**: Creates trading pairs
- **UniswapV2Pair**: USDC/WETH pair with initial liquidity (1M USDC + 10 ETH)
- **HooksPerpetualAuction**: Competitive bidding system for blockchain event hooks with MEV sharing
- Contract addresses saved to: `data/contracts/addresses.env`

## Important Notes for Claude

- All contract deployment uses Foundry `forge script` approach
- Uses OP Stack system WETH contract (not custom deployment)
- Builder RPC at `http://localhost:2222` is used for contract deployment
- Contract addresses are extracted from forge script JSON output using `jq`
- Liquidity pool verification commands are provided in README
- HooksPerpetualAuction uses OpenZeppelin contracts for Ownable and ReentrancyGuard
- HooksPerpetualAuction requires Solidity 0.8.20 or higher

## Dependencies

- Docker (for OP Stack components)
- Go (for builder-playground)
- Rust/Cargo (for op-rbuilder)
- Foundry (cast, forge for contract interactions)
- jq (for JSON parsing of deployment outputs)
- bc (for balance calculations)