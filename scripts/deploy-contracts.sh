#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📦 Deploying all contracts...${NC}"

# Load environment variables from .env file
if [ -f .env ]; then
    echo -e "${YELLOW}Loading environment variables from .env file...${NC}"
    set -a  # automatically export all variables
    source .env
    set +a  # disable automatic export
else
    echo -e "${RED}❌ .env file not found${NC}"
    echo -e "${YELLOW}Please create .env file with required variables:${NC}"
    echo -e "  L2_RPC_URL=http://localhost:2222"
    echo -e "  DEPLOYER_PRIVATE_KEY=0x..."
    echo -e "  DEPLOYER_ADDRESS=0x..."
    exit 1
fi

mkdir -p data/contracts

# Validate required environment variables
if [ -z "$L2_RPC_URL" ] || [ -z "$DEPLOYER_PRIVATE_KEY" ] || [ -z "$DEPLOYER_ADDRESS" ]; then
    echo -e "${RED}❌ Missing required environment variables in .env file${NC}"
    echo -e "${YELLOW}Required: L2_RPC_URL, DEPLOYER_PRIVATE_KEY, DEPLOYER_ADDRESS${NC}"
    exit 1
fi

# Export environment variables for child scripts
export L2_RPC_URL
export DEPLOYER_PRIVATE_KEY
export DEPLOYER_ADDRESS

# Clear previous addresses file
> data/contracts/addresses.env

echo -e "${YELLOW}Starting modular contract deployment...${NC}"
echo -e "${BLUE}Using deployer: $DEPLOYER_ADDRESS${NC}"
echo -e "${BLUE}Using RPC: $L2_RPC_URL${NC}"

# 1. Deploy SimpleToken
echo -e "\n${YELLOW}=== Step 1: Deploying SimpleToken ===${NC}"
bash scripts/deploy-simple-token.sh

# Source the addresses to get TOKEN_ADDRESS for UniswapV2
source data/contracts/addresses.env
export TOKEN_ADDRESS

# 2. Deploy Uniswap V2 (2 factories with liquidity)
echo -e "\n${YELLOW}=== Step 2: Deploying Uniswap V2 ===${NC}"
bash scripts/deploy-uniswapv2.sh

# 3. Deploy HooksPerpetualAuction
echo -e "\n${YELLOW}=== Step 3: Deploying HooksPerpetualAuction ===${NC}"
bash scripts/deploy-base-hooks.sh

# 4. Deploy UniswapV2ArbHook
echo -e "\n${YELLOW}=== Step 4: Deploying UniswapV2ArbHook ===${NC}"
bash scripts/deploy-arb-hook.sh

# Final summary
echo -e "\n${GREEN}🎉 All contract deployments complete!${NC}"
echo -e "${BLUE}📋 Contract addresses saved to data/contracts/addresses.env${NC}"

# Display final summary
echo -e "\n${BLUE}📋 Deployment Summary:${NC}"
source data/contracts/addresses.env
echo -e "  • SimpleToken: $TOKEN_ADDRESS"
echo -e "  • WETH (System): $WETH_ADDRESS"
echo -e "  • Uniswap V2 Factory 1: $FACTORY1_ADDRESS"
echo -e "  • Uniswap V2 Router 1: $ROUTER1_ADDRESS"
echo -e "  • Uniswap V2 Factory 2: $FACTORY2_ADDRESS"
echo -e "  • Uniswap V2 Router 2: $ROUTER2_ADDRESS"
echo -e "  • Uniswap V2 Pair 1: $PAIR1_ADDRESS"
echo -e "  • Uniswap V2 Pair 2: $PAIR2_ADDRESS"
echo -e "  • HooksPerpetualAuction: $HOOKS_ADDRESS"
echo -e "  • UniswapV2ArbHook: $ARB_HOOK_ADDRESS"
echo -e "  • Deployer Address: $DEPLOYER_ADDRESS"

echo -e "\n${GREEN}✅ Ready for testing and interaction!${NC}"