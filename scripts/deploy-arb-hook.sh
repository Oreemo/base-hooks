#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🎯 Deploying UniswapV2ArbHook...${NC}"

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

# Check required environment variables
if [ -z "$L2_RPC_URL" ] || [ -z "$DEPLOYER_PRIVATE_KEY" ] || [ -z "$DEPLOYER_ADDRESS" ]; then
    echo -e "${RED}❌ Missing required environment variables${NC}"
    echo -e "${YELLOW}Required: L2_RPC_URL, DEPLOYER_PRIVATE_KEY, DEPLOYER_ADDRESS${NC}"
    exit 1
fi

mkdir -p data/contracts

echo -e "${YELLOW}Deploying UniswapV2ArbHook to builder at $L2_RPC_URL...${NC}"

# Deploy UniswapV2ArbHook using forge script
cd contracts/base-hooks

ARB_HOOK_ADDRESS=$(forge script script/UniswapV2ArbHook.s.sol:UniswapV2ArbHookScript --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --json | jq -rc 'select(.contract_address) | .contract_address')

if [ -z "$ARB_HOOK_ADDRESS" ] || [ "$ARB_HOOK_ADDRESS" = "null" ]; then
    echo -e "${RED}❌ Failed to deploy UniswapV2ArbHook${NC}"
    exit 1
fi

cd ../..
echo "ARB_HOOK_ADDRESS=$ARB_HOOK_ADDRESS" >>data/contracts/addresses.env
echo -e "${GREEN}✅ UniswapV2ArbHook deployed at: $ARB_HOOK_ADDRESS${NC}"

# Get contract details
echo -e "${YELLOW}Fetching contract details...${NC}"
MIN_PROFIT=$(cast call --rpc-url $L2_RPC_URL $ARB_HOOK_ADDRESS "minProfitThreshold()")
MIN_PROFIT_ETH=$(cast to-dec $MIN_PROFIT)
MIN_PROFIT_FORMATTED=$(echo "scale=4; $MIN_PROFIT_ETH / 1000000000000000000" | bc -l)

MAX_TRADE=$(cast call --rpc-url $L2_RPC_URL $ARB_HOOK_ADDRESS "maxTradeSize()")
MAX_TRADE_ETH=$(cast to-dec $MAX_TRADE)
MAX_TRADE_FORMATTED=$(echo "scale=0; $MAX_TRADE_ETH / 1000000000000000000" | bc -l)

GAS_BUFFER=$(cast call --rpc-url $L2_RPC_URL $ARB_HOOK_ADDRESS "gasCostBuffer()")
GAS_BUFFER_ETH=$(cast to-dec $GAS_BUFFER)
GAS_BUFFER_FORMATTED=$(echo "scale=2; $GAS_BUFFER_ETH / 1000000000000000000" | bc -l)

SEQUENCER=$(cast call --rpc-url $L2_RPC_URL $ARB_HOOK_ADDRESS "sequencer()")

echo -e "${GREEN}✅ UniswapV2ArbHook deployment complete!${NC}"
echo -e "${BLUE}📋 UniswapV2ArbHook details:${NC}"
echo -e "  • Contract Address: $ARB_HOOK_ADDRESS"
echo -e "  • Owner: $DEPLOYER_ADDRESS"
echo -e "  • Sequencer: $SEQUENCER"
echo -e "  • Min Profit Threshold: $MIN_PROFIT_FORMATTED ETH"
echo -e "  • Max Trade Size: $MAX_TRADE_FORMATTED ETH"
echo -e "  • Gas Cost Buffer: $GAS_BUFFER_FORMATTED ETH"
echo -e "  • Supported DEXes: 0 (needs configuration)"
