#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📦 Deploying SimpleToken...${NC}"

# Load environment variables from .env file if not already loaded
if [ -z "$L2_RPC_URL" ]; then
    if [ -f .env ]; then
        echo -e "${YELLOW}Loading environment variables from .env file...${NC}"
        set -a  # automatically export all variables
        source .env
        set +a  # disable automatic export
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

echo -e "${YELLOW}Deploying SimpleToken to builder at $L2_RPC_URL...${NC}"

# Deploy using forge script
cd contracts/simple-token
forge install OpenZeppelin/openzeppelin-contracts --no-commit 2>/dev/null || true

TOKEN_ADDRESS=$(forge script script/SimpleToken.s.sol:SimpleTokenScript --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --json | jq -rc 'select(.contract_address) | .contract_address')

if [ -z "$TOKEN_ADDRESS" ] || [ "$TOKEN_ADDRESS" = "null" ]; then
    echo -e "${RED}❌ Failed to deploy SimpleToken${NC}"
    exit 1
fi

cd ../..
echo "TOKEN_ADDRESS=$TOKEN_ADDRESS" >> data/contracts/addresses.env
echo -e "${GREEN}✅ SimpleToken deployed at: $TOKEN_ADDRESS${NC}"

# Check balance
BALANCE=$(cast call --rpc-url $L2_RPC_URL $TOKEN_ADDRESS "balanceOf(address)" $DEPLOYER_ADDRESS)
BALANCE_FORMATTED=$(cast to-dec $BALANCE)
BALANCE_TOKENS=$(echo "scale=0; $BALANCE_FORMATTED / 1000000000000000000" | bc)

echo -e "${BLUE}📋 SimpleToken details:${NC}"
echo -e "  • Contract Address: $TOKEN_ADDRESS"
echo -e "  • Initial Supply: 1,000,000,000 tokens"
echo -e "  • Deployer Balance: $BALANCE_TOKENS tokens"