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

echo -e "\n${YELLOW}=== Deploying all contracts ===${NC}"
cd solidity
DEPLOYMENT_ADDRESSES=$(forge script script/FullDeploy.s.sol:FullDeploy --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast --json | jq -r '.logs[0]' | head -n 1)
cd ..

TOKEN_ADDRESS=$(echo $DEPLOYMENT_ADDRESSES | jq -r '.token')
WETH_ADDRESS=$(echo $DEPLOYMENT_ADDRESSES | jq -r '.weth')
FACTORY1_ADDRESS=$(echo $DEPLOYMENT_ADDRESSES | jq -r '.factory1')
ROUTER1_ADDRESS=$(echo $DEPLOYMENT_ADDRESSES | jq -r '.router1')
PAIR1_ADDRESS=$(echo $DEPLOYMENT_ADDRESSES | jq -r '.pair1')
FACTORY2_ADDRESS=$(echo $DEPLOYMENT_ADDRESSES | jq -r '.factory2')
ROUTER2_ADDRESS=$(echo $DEPLOYMENT_ADDRESSES | jq -r '.router2')
PAIR2_ADDRESS=$(echo $DEPLOYMENT_ADDRESSES | jq -r '.pair2')
HOOKS_ADDRESS=$(echo $DEPLOYMENT_ADDRESSES | jq -r '.hooksPerpetualAuction')
ARB_HOOK_ADDRESS=$(echo $DEPLOYMENT_ADDRESSES | jq -r '.arbHook')

echo "TOKEN_ADDRESS=$TOKEN_ADDRESS" >>data/contracts/addresses.env
echo "WETH_ADDRESS=$WETH_ADDRESS" >>data/contracts/addresses.env
echo "FACTORY1_ADDRESS=$FACTORY1_ADDRESS" >>data/contracts/addresses.env
echo "ROUTER1_ADDRESS=$ROUTER1_ADDRESS" >>data/contracts/addresses.env
echo "PAIR1_ADDRESS=$PAIR1_ADDRESS" >>data/contracts/addresses.env
echo "FACTORY2_ADDRESS=$FACTORY2_ADDRESS" >>data/contracts/addresses.env
echo "ROUTER2_ADDRESS=$ROUTER2_ADDRESS" >>data/contracts/addresses.env
echo "PAIR2_ADDRESS=$PAIR2_ADDRESS" >>data/contracts/addresses.env
echo "HOOKS_ADDRESS=$HOOKS_ADDRESS" >>data/contracts/addresses.env
echo "ARB_HOOK_ADDRESS=$ARB_HOOK_ADDRESS" >>data/contracts/addresses.env

# Display final summary
echo -e "\n${BLUE}📋 Deployment Summary:${NC}"
# source data/contracts/addresses.env
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