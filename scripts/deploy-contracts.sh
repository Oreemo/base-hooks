#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📦 Deploying simple ERC20 token...${NC}"

# Default RPC URL for builder
L2_RPC_URL=${L2_RPC_URL:-"http://localhost:2222"}

mkdir -p data/contracts

# Pre-funded account from OP Stack devnet (typical default)
DEPLOYER_PRIVATE_KEY="0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6"
DEPLOYER_ADDRESS="0xa0Ee7A142d267C1f36714E4a8F75612F20a79720"

echo -e "${YELLOW}Deploying contracts to builder at $L2_RPC_URL...${NC}"

# Deploy simple ERC20 token using forge create
echo -e "${YELLOW}Deploying test USDC token...${NC}"

# Deploy using forge
cd contracts/simple-token
TOKEN_ADDRESS=$(forge script script/SimpleToken.s.sol:SimpleTokenScript --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --json | jq -rc 'select(.contract_address) | .contract_address')

if [ -z "$TOKEN_ADDRESS" ] || [ "$TOKEN_ADDRESS" = "null" ]; then
    echo -e "${RED}❌ Failed to deploy TEST token${NC}"
    exit 1
fi

cd ../..
echo "TOKEN_ADDRESS=$TOKEN_ADDRESS" >data/contracts/addresses.env
echo -e "${GREEN}✅ TEST token deployed at: $TOKEN_ADDRESS${NC}"

# # Mint additional tokens to the specified address (already has 1B from constructor)
# echo -e "${YELLOW}Minting additional TEST tokens to $DEPLOYER_ADDRESS...${NC}"
# cast send --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY $TOKEN_ADDRESS "mint(address,uint256)" $DEPLOYER_ADDRESS 1000000000000000000000000000 # 1 billion more tokens

# Check balance
BALANCE=$(cast call --rpc-url $L2_RPC_URL $TOKEN_ADDRESS "balanceOf(address)" $DEPLOYER_ADDRESS)
BALANCE_FORMATTED=$(cast to-dec $BALANCE)

echo -e "${GREEN}✅ Contract deployment complete!${NC}"
echo -e "${BLUE}📋 Contract addresses saved to data/contracts/addresses.env${NC}"
echo -e "${BLUE}📋 Contract details:${NC}"
echo -e "  • TEST Token: $TOKEN_ADDRESS"
echo -e "  • Funded Address: $DEPLOYER_ADDRESS"
echo -e "  • Balance: $(echo "scale=0; $BALANCE_FORMATTED / 1000000000000000000" | bc) USDC tokens"
