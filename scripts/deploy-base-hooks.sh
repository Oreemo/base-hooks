#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🎯 Deploying HooksPerpetualAuction...${NC}"

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

echo -e "${YELLOW}Deploying HooksPerpetualAuction to builder at $L2_RPC_URL...${NC}"

# Deploy HooksPerpetualAuction using forge script
cd contracts/base-hooks

# Use deterministic deployment if DETERMINISTIC flag is set
if [ "$DETERMINISTIC" = "true" ]; then
    # allow for failure (due to already deployed)
    echo -e "${YELLOW}Using deterministic deployment with CREATE2...${NC}"
    HOOKS_ADDRESS=$(forge script script/HooksPerpetualAuctionDeterministic.s.sol:HooksPerpetualAuctionDeterministicScript --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --json) || true

    # get the computed address
    HOOKS_ADDRESS=$(forge script script/HooksPerpetualAuctionDeterministic.s.sol:HooksPerpetualAuctionDeterministicScript --sig "getPrecomputedAddress()" | grep -o '0x[a-fA-F0-9]\{40\}')
else
    echo -e "${YELLOW}Using standard deployment...${NC}"
    HOOKS_ADDRESS=$(forge script script/HooksPerpetualAuction.s.sol:HooksPerpetualAuctionScript --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --json | jq -rc 'select(.contract_address) | .contract_address')
fi

if [ -z "$HOOKS_ADDRESS" ] || [ "$HOOKS_ADDRESS" = "null" ]; then
    echo -e "${RED}❌ Failed to deploy HooksPerpetualAuction${NC}"
    exit 1
fi

cd ../..
echo "HOOKS_ADDRESS=$HOOKS_ADDRESS" >>data/contracts/addresses.env
echo -e "${GREEN}✅ HooksPerpetualAuction deployed at: $HOOKS_ADDRESS${NC}"

# Get contract details
echo -e "${YELLOW}Fetching contract details...${NC}"
EXCESS_ETH=$(cast call --rpc-url $L2_RPC_URL $HOOKS_ADDRESS "getExcessETH()")

echo -e "${GREEN}✅ HooksPerpetualAuction deployment complete!${NC}"
echo -e "${BLUE}📋 HooksPerpetualAuction details:${NC}"
echo -e "  • Contract Address: $HOOKS_ADDRESS"
echo -e "  • Owner: $DEPLOYER_ADDRESS"
echo -e "  • ExcessETH: $EXCESS_ETH%"
