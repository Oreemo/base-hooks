# Base Hooks - OP Stack Devnet with Flashblocks

Quickly spin up an OP Stack devnet with flashblocks capability and pre-deployed ERC20 token + Uniswap V2 + HooksPerpetualAuction contracts.

## Features

- 🚀 **One-command setup**: Complete OP Stack L1/L2 devnet with flashblocks
- ⚡ **Flashblocks enabled**: Uses op-rbuilder for flashblocks capability
- 🦄 **Uniswap V2 ready**: Pre-deployed Uniswap V2 Factory with liquidity pools
- 🎯 **HooksPerpetualAuction**: Competitive bidding system for blockchain event hooks
- 💰 **Test token included**: ERC20 test token with 1B initial supply
- 🔑 **Funded accounts**: Pre-funded deployer account with private key
- 🧹 **Easy cleanup**: One command to clean everything

## Quick Start

1. **Setup prerequisites**:
   ```bash
   just setup
   ```

2. **Configure environment**:
   ```bash
   # .env file should already contain:
   # L2_RPC_URL=http://localhost:2222
   # DEPLOYER_PRIVATE_KEY=0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6
   # DEPLOYER_ADDRESS=0xa0Ee7A142d267C1f36714E4a8F75612F20a79720
   # WETH_ADDRESS=0x4200000000000000000000000000000000000006
   ```

3. **Start the devnet**:
   ```bash
   just start
   ```

4. **View funded accounts**:
   ```bash
   just accounts
   ```

5. **Stop when done**:
   ```bash
   just stop
   ```

## Available Commands

- `just setup` - Install prerequisites (Docker, Go, Rust, Foundry)
- `just start` - Start devnet with flashblocks and deploy contracts
- `just stop` - Stop the devnet
- `just clean` - Clean up all data and processes
- `just deploy` - Deploy contracts only (if devnet is running)
- `just deploy-hooks` - Deploy HooksPerpetualAuction contract
- `just accounts` - Show funded accounts with private keys

## Network Details

- **L1 RPC**: `http://localhost:8545`
- **L2 RPC**: `http://localhost:8546`
- **Builder RPC**: `http://localhost:2222`
- **Chain ID**: 901 (L2) / 900 (L1)
- **Flashblocks**: `ws://localhost:8080`

## What Gets Deployed

- **SimpleToken**: ERC20 test token with 1B initial supply (18 decimals)
- **Uniswap V2 Factory**: For creating trading pairs
- **USDC/WETH Pair**: Pre-created liquidity pool with 1M USDC + 10 ETH
- **HooksPerpetualAuction**: Perpetual auction system for blockchain event hooks
- **System WETH**: Uses OP Stack predeploy at `0x4200000000000000000000000000000000000006`

## Contract Verification

After deployment, verify your liquidity pool:

```bash
# Source contract addresses
source data/contracts/addresses.env

# Check pair reserves (should show ~1M tokens + ~10 ETH)
cast call --rpc-url http://localhost:2222 $PAIR_ADDRESS "getReserves()"

# Verify token addresses in pair
cast call --rpc-url http://localhost:2222 $PAIR_ADDRESS "token0()"
cast call --rpc-url http://localhost:2222 $PAIR_ADDRESS "token1()"

# Check your LP token balance
cast call --rpc-url http://localhost:2222 $PAIR_ADDRESS "balanceOf(address)" $DEPLOYER_ADDRESS
```

## Requirements

- Docker
- Git
- Internet connection (for downloading dependencies)

The setup script will automatically install:
- Go (for builder-playground)
- Rust (for op-rbuilder)
- Foundry (for contract interactions)

## Project Structure

```
contracts/
├── simple-token/          # ERC20 token Foundry project
│   ├── src/SimpleToken.sol
│   └── script/SimpleToken.s.sol
├── uniswapv2/            # Uniswap V2 Foundry project
│   ├── src/UniswapV2Factory.sol
│   └── script/UniswapV2.s.sol
└── base-hooks/           # HooksPerpetualAuction Foundry project
    ├── src/HooksPerpetualAuction.sol
    └── script/HooksPerpetualAuction.s.sol
scripts/
├── setup.sh              # Prerequisites installation
├── start-devnet.sh       # OP Stack + op-rbuilder startup
├── deploy-contracts.sh   # Contract deployment
├── deploy-hooks.sh       # HooksPerpetualAuction deployment
└── cleanup.sh            # Cleanup processes
```

## Troubleshooting

- Check logs in `logs/` directory
- Use `just clean` to reset everything
- Ensure Docker is running before starting
- Contract addresses are saved to `data/contracts/addresses.env`

## License

MIT