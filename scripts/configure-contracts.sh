#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}⚙️  Configuring all contracts...${NC}"

# Load environment variables from .env file if not already loaded
if [ -z "$L2_RPC_URL" ]; then
    if [ -f .env ]; then
        echo -e "${YELLOW}Loading environment variables from .env file...${NC}"
        set -a # automatically export all variables
        source .env
        set +a # disable automatic export
    else
        echo -e "${RED}❌ .env file not found and no environment variables provided${NC}"
        exit 1
    fi
fi

# Validate required environment variables
if [ -z "$L2_RPC_URL" ] || [ -z "$DEPLOYER_PRIVATE_KEY" ] || [ -z "$DEPLOYER_ADDRESS" ]; then
    echo -e "${RED}❌ Missing required environment variables${NC}"
    echo -e "${YELLOW}Required: L2_RPC_URL, DEPLOYER_PRIVATE_KEY, DEPLOYER_ADDRESS${NC}"
    exit 1
fi

# Ensure contract addresses are available
if [ ! -f data/contracts/addresses.env ]; then
    echo -e "${RED}❌ Contract addresses file not found${NC}"
    echo -e "${YELLOW}Please deploy contracts first using: just deploy${NC}"
    exit 1
fi

echo -e "${YELLOW}Starting contract configuration...${NC}"

# 1. Configure HooksPerpetualAuction
echo -e "\n${YELLOW}=== Step 1: Configuring HooksPerpetualAuction ===${NC}"
bash scripts/configure-hooks.sh

# 2. Configure UniswapV2ArbHook 
echo -e "\n${YELLOW}=== Step 2: Configuring UniswapV2ArbHook ===${NC}"
bash scripts/configure-arb-hook.sh

echo -e "\n${GREEN}🎉 All contract configurations complete!${NC}"
echo -e "${BLUE}📋 Configuration Summary:${NC}"
echo -e "  • HooksPerpetualAuction: Configured with 20% originator share"
echo -e "  • UniswapV2ArbHook: Configured with 2 DEXes and arbitrage parameters"
echo -e "  • Token authorizations: TOKEN and WETH authorized for arbitrage"
echo -e "  • Initial balances: 100K tokens + 1 ETH provided to arbitrage contract"

echo -e "\n${GREEN}✅ System ready for arbitrage detection and execution!${NC}"