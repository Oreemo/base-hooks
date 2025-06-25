#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🎯 Deploying HooksPerpetualAuction contract...${NC}"

# Default RPC URL for builder
L2_RPC_URL=${L2_RPC_URL:-"http://localhost:2222"}

mkdir -p data/contracts

# Pre-funded account from OP Stack devnet (typical default)
DEPLOYER_PRIVATE_KEY="0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6"
DEPLOYER_ADDRESS="0xa0Ee7A142d267C1f36714E4a8F75612F20a79720"

echo -e "${YELLOW}Deploying HooksPerpetualAuction to builder at $L2_RPC_URL...${NC}"

# Deploy HooksPerpetualAuction using forge script
echo -e "${YELLOW}Deploying HooksPerpetualAuction contract...${NC}"
cd contracts/base-hooks

HOOKS_ADDRESS=$(forge script script/HooksPerpetualAuction.s.sol:HooksPerpetualAuctionScript --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --json | jq -rc 'select(.contract_address) | .contract_address')

if [ -z "$HOOKS_ADDRESS" ] || [ "$HOOKS_ADDRESS" = "null" ]; then
    echo -e "${RED}❌ Failed to deploy HooksPerpetualAuction${NC}"
    exit 1
fi

cd ../..
echo "HOOKS_ADDRESS=$HOOKS_ADDRESS" >>data/contracts/addresses.env
echo -e "${GREEN}✅ HooksPerpetualAuction deployed at: $HOOKS_ADDRESS${NC}"

# Get contract details
echo -e "${YELLOW}Fetching contract details...${NC}"
ORIGINATOR_SHARE=$(cast call --rpc-url $L2_RPC_URL $HOOKS_ADDRESS "originatorShareBps()")
ORIGINATOR_SHARE_PERCENT=$(echo "scale=2; $ORIGINATOR_SHARE / 100" | bc)
GAS_STIPEND=$(cast call --rpc-url $L2_RPC_URL $HOOKS_ADDRESS "hookGasStipend()")
MIN_CALLS=$(cast call --rpc-url $L2_RPC_URL $HOOKS_ADDRESS "MIN_CALLS_DEPOSIT()")

echo -e "${GREEN}✅ HooksPerpetualAuction deployment complete!${NC}"
echo -e "${BLUE}📋 Contract details:${NC}"
echo -e "  • Contract Address: $HOOKS_ADDRESS"
echo -e "  • Owner: $DEPLOYER_ADDRESS"
echo -e "  • Originator Share: $ORIGINATOR_SHARE_PERCENT%"
echo -e "  • Hook Gas Stipend: $GAS_STIPEND"
echo -e "  • Minimum Calls Deposit: $MIN_CALLS"
echo -e "${BLUE}💡 Contract addresses saved to data/contracts/addresses.env${NC}"
