#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Debugging CREATE2 address collision...${NC}"

# Load environment variables from .env file
if [ -f .env ]; then
    echo -e "${YELLOW}Loading environment variables from .env file...${NC}"
    set -a
    source .env
    set +a
else
    echo -e "${RED}❌ .env file not found${NC}"
    exit 1
fi

cd contracts/base-hooks

echo -e "${YELLOW}Checking if address already has code...${NC}"

# Compute the CREATE2 address
COMPUTED_ADDRESS=$(forge script script/HooksPerpetualAuctionDeterministic.s.sol:HooksPerpetualAuctionDeterministicScript --sig "getPrecomputedAddress()" --rpc-url $L2_RPC_URL 2>/dev/null | grep "0x" | tail -1)

echo -e "${BLUE}Computed CREATE2 address: $COMPUTED_ADDRESS${NC}"

# Check if there's already code at this address
CODE_SIZE=$(cast code $COMPUTED_ADDRESS --rpc-url $L2_RPC_URL 2>/dev/null | wc -c)

if [ "$CODE_SIZE" -gt 4 ]; then
    echo -e "${RED}❌ Address collision detected!${NC}"
    echo -e "${YELLOW}Address $COMPUTED_ADDRESS already has code deployed${NC}"
    echo -e "${YELLOW}Code size: $CODE_SIZE characters${NC}"
    
    # Check what contract is deployed there
    echo -e "${YELLOW}Checking deployed contract...${NC}"
    EXISTING_CODE=$(cast code $COMPUTED_ADDRESS --rpc-url $L2_RPC_URL)
    echo -e "${BLUE}First 100 chars of existing code: ${EXISTING_CODE:0:100}...${NC}"
else
    echo -e "${GREEN}✅ Address is available for deployment${NC}"
    echo -e "${BLUE}Code size: $CODE_SIZE characters (empty)${NC}"
fi

# Show current nonce of deployer
NONCE=$(cast nonce $DEPLOYER_ADDRESS --rpc-url $L2_RPC_URL)
echo -e "${BLUE}Deployer nonce: $NONCE${NC}"

cd ../..