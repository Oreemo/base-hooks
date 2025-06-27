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

5. **Configure contracts** (optional - done automatically):
   ```bash
   just configure
   ```

6. **Stop when done**:
   ```bash
   just stop
   ```

## Available Commands

- `just setup` - Install prerequisites (Docker, Go, Rust, Foundry)
- `just start` - Start devnet with flashblocks and deploy contracts
- `just stop` - Stop the devnet
- `just clean` - Clean up all data and processes
- `just deploy` - Deploy contracts only (if devnet is running)
- `just start-devnet` - Start devnet only (no contracts)
- `just deploy-simple-token` - Deploy SimpleToken only
- `just deploy-uniswapv2` - Deploy Uniswap V2 only
- `just deploy-base-hooks` - Deploy HooksPerpetualAuction only
- `just deploy-base-hooks-deterministic` - Deploy HooksPerpetualAuction with deterministic address
- `just deploy-arb-hook` - Deploy UniswapV2ArbHook only
- `just configure` - Configure all deployed contracts
- `just configure-hooks` - Configure HooksPerpetualAuction only
- `just configure-arb-hook` - Configure UniswapV2ArbHook only
- `just restart-rbuilder` - Build and restart op-rbuilder
- `just place-bid` - Place bid on HooksPerpetualAuction
- `just trigger-swap` - Trigger a Uniswap V2 swap
- `just update-bindings` - Update Rust bindings from contracts
- `just compute-hook-address` - Compute deterministic hook address
- `just debug-collision` - Debug address collision
- `just accounts` - Show funded accounts with private keys

## Network Details

- **L1 RPC**: `http://localhost:8545`
- **L2 RPC**: `http://localhost:8546`
- **Builder RPC**: `http://localhost:2222`
- **Chain ID**: 901 (L2) / 900 (L1)
- **Flashblocks**: `ws://localhost:8080`

## What Gets Deployed

- **MockERC20**: ERC20 test token with 1B initial supply (18 decimals)
- **Uniswap V2 Factory**: For creating trading pairs (2 factories deployed)
- **Uniswap V2 Router**: For easy token swaps with slippage protection (2 routers deployed)
- **TOKEN/WETH Pairs**: Pre-created liquidity pools with different ratios
- **HooksPerpetualAuction**: Perpetual auction system for blockchain event hooks with MEV sharing
- **UniswapV2ArbHook**: Arbitrage detection and execution hook for Uniswap V2
- **System WETH**: Uses OP Stack predeploy at `0x4200000000000000000000000000000000000006`

## Contract Configuration

The deployment automatically configures all contracts with optimal settings:

### HooksPerpetualAuction Configuration:
- **Originator Share**: 20% (2000 basis points) - MEV refund to transaction originators
- **Hook Gas Stipend**: 1M gas - Gas limit for hook execution
- **Min Calls Deposit**: 100 calls - Minimum auction duration

### UniswapV2ArbHook Configuration:
- **Sequencer**: Set to HooksPerpetualAuction contract address
- **Supported DEXes**: Both deployed Uniswap V2 routers registered
- **Authorized Tokens**: TOKEN and WETH enabled for arbitrage
- **Arbitrage Parameters**:
  - Min Profit Threshold: 0.001 ETH
  - Max Trade Size: 5 ETH  
  - Gas Cost Buffer: 0.005 ETH
- **Initial Balances**: 100K tokens + 1 ETH for arbitrage execution
- **Pair Registry**: Both TOKEN/WETH pairs registered with their respective DEXes

## Contract Verification

After deployment, verify your contracts and liquidity pools:

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

# Test the system by triggering a swap (generates events for hooks)
just trigger-swap

# Place a bid on the auction system
just place-bid
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
solidity/                   # Unified Foundry project
├── src/
│   ├── HooksPerpetualAuction.sol    # Perpetual auction system
│   ├── UniswapV2ArbHook.sol         # Arbitrage detection hook
│   ├── UniswapV2Factory.sol         # Uniswap V2 factory
│   ├── UniswapV2Pair.sol            # Uniswap V2 pair
│   ├── UniswapV2Router.sol          # Uniswap V2 router
│   └── UQ112x112.sol               # Fixed point math library
├── script/
│   ├── FullDeploy.s.sol            # Complete deployment script
│   └── TriggerSwap.s.sol           # Swap testing script
└── test/
    └── TestUniswapV2Swap.t.sol     # Swap tests
scripts/
├── setup.sh                        # Prerequisites installation
├── start-devnet.sh                 # OP Stack + op-rbuilder startup
├── stop-devnet.sh                  # Stop devnet
├── restart-rbuilder.sh             # Restart op-rbuilder
├── deploy-contracts.sh             # Contract deployment
├── place-bid-simple.sh             # Place auction bid
├── trigger-swap.sh                 # Trigger test swap
├── show-accounts.sh                # Show funded accounts
└── cleanup.sh                      # Cleanup processes
```

## Troubleshooting

- Check logs in `logs/` directory
- Use `just clean` to reset everything
- Ensure Docker is running before starting
- Contract addresses are saved to `data/contracts/addresses.env`

## License

MIT