#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Computing deterministic HooksPerpetualAuction address...${NC}"

# Load environment variables from .env file
if [ -f .env ]; then
    echo -e "${YELLOW}Loading environment variables from .env file...${NC}"
    set -a # automatically export all variables
    source .env
    set +a # disable automatic export
else
    echo -e "${RED}❌ .env file not found${NC}"
    exit 1
fi

cd contracts/base-hooks

# Use forge to compute the address
echo -e "${YELLOW}Computing CREATE2 address...${NC}"

COMPUTED_ADDRESS=$(forge script script/HooksPerpetualAuctionDeterministic.s.sol:HooksPerpetualAuctionDeterministicScript --sig "getPrecomputedAddress()" | grep "0x" | tail -1)

echo -e "${GREEN}✅ Computed deterministic address: $COMPUTED_ADDRESS${NC}"
echo -e "${BLUE}📋 Deployment info:${NC}"
echo -e "  • Address: $COMPUTED_ADDRESS"
echo -e "  • Salt: keccak256('HooksPerpetualAuction_v1.0.0')"
echo -e "  • Deployer: $DEPLOYER_ADDRESS"
echo -e "  • Network: $L2_RPC_URL"

cd ../..
