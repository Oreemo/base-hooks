#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🦄 Deploying Uniswap V2 contracts...${NC}"

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
if [ -z "$L2_RPC_URL" ] || [ -z "$DEPLOYER_PRIVATE_KEY" ] || [ -z "$DEPLOYER_ADDRESS" ] || [ -z "$TOKEN_ADDRESS" ]; then
    echo -e "${RED}❌ Missing required environment variables${NC}"
    echo -e "${YELLOW}Required: L2_RPC_URL, DEPLOYER_PRIVATE_KEY, DEPLOYER_ADDRESS, TOKEN_ADDRESS${NC}"
    exit 1
fi

mkdir -p data/contracts

# Use OP Stack system WETH contract (from .env if available, otherwise use default)
echo -e "${YELLOW}Using OP Stack system WETH contract...${NC}"
WETH_ADDRESS=${WETH_ADDRESS:-"0x4200000000000000000000000000000000000006"}
echo "WETH_ADDRESS=$WETH_ADDRESS" >> data/contracts/addresses.env
echo -e "${GREEN}✅ Using system WETH at: $WETH_ADDRESS${NC}"

# Deploy first Uniswap V2 Factory
echo -e "${YELLOW}Deploying first Uniswap V2 Factory...${NC}"
cd contracts/uniswapv2

FACTORY1_ADDRESS=$(PRIVATE_KEY=$DEPLOYER_PRIVATE_KEY forge script script/UniswapV2.s.sol:UniswapV2Script --rpc-url $L2_RPC_URL --broadcast --json | jq -rc 'select(.contract_address) | .contract_address')

if [ -z "$FACTORY1_ADDRESS" ] || [ "$FACTORY1_ADDRESS" = "null" ]; then
    echo -e "${RED}❌ Failed to deploy first Uniswap V2 Factory${NC}"
    exit 1
fi

echo "FACTORY1_ADDRESS=$FACTORY1_ADDRESS" >> ../../data/contracts/addresses.env
echo -e "${GREEN}✅ First Uniswap V2 Factory deployed at: $FACTORY1_ADDRESS${NC}"

# Deploy second Uniswap V2 Factory
echo -e "${YELLOW}Deploying second Uniswap V2 Factory...${NC}"

FACTORY2_ADDRESS=$(PRIVATE_KEY=$DEPLOYER_PRIVATE_KEY forge script script/UniswapV2.s.sol:UniswapV2Script --rpc-url $L2_RPC_URL --broadcast --json | jq -rc 'select(.contract_address) | .contract_address')

if [ -z "$FACTORY2_ADDRESS" ] || [ "$FACTORY2_ADDRESS" = "null" ]; then
    echo -e "${RED}❌ Failed to deploy second Uniswap V2 Factory${NC}"
    exit 1
fi

echo "FACTORY2_ADDRESS=$FACTORY2_ADDRESS" >> ../../data/contracts/addresses.env
echo -e "${GREEN}✅ Second Uniswap V2 Factory deployed at: $FACTORY2_ADDRESS${NC}"

cd ../..

# Create and add liquidity to first pair (TOKEN/WETH)
echo -e "${YELLOW}Creating TOKEN/WETH pair on first factory...${NC}"
cast send --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY $FACTORY1_ADDRESS "createPair(address,address)" $TOKEN_ADDRESS $WETH_ADDRESS

PAIR1_ADDRESS=$(cast call --rpc-url $L2_RPC_URL $FACTORY1_ADDRESS "getPair(address,address)" $TOKEN_ADDRESS $WETH_ADDRESS | cast parse-bytes32-address)
echo "PAIR1_ADDRESS=$PAIR1_ADDRESS" >> data/contracts/addresses.env
echo -e "${GREEN}✅ First pair created at: $PAIR1_ADDRESS${NC}"

# Add liquidity to first pair (1M tokens + 10 ETH)
echo -e "${YELLOW}Adding liquidity to first pair (1M tokens + 10 ETH)...${NC}"

# Wrap 10 ETH to WETH
cast send --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY $WETH_ADDRESS "deposit()" --value 10000000000000000000

# Transfer tokens to first pair
cast send --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY $TOKEN_ADDRESS "transfer(address,uint256)" $PAIR1_ADDRESS 1000000000000000000000000 # 1M tokens
cast send --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY $WETH_ADDRESS "transfer(address,uint256)" $PAIR1_ADDRESS 10000000000000000000 # 10 WETH

# Mint liquidity tokens for first pair
cast send --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY $PAIR1_ADDRESS "mint(address)" $DEPLOYER_ADDRESS

echo -e "${GREEN}✅ Liquidity added to first pair${NC}"

# Create and add liquidity to second pair (TOKEN/WETH with different ratio)
echo -e "${YELLOW}Creating TOKEN/WETH pair on second factory...${NC}"
cast send --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY $FACTORY2_ADDRESS "createPair(address,address)" $TOKEN_ADDRESS $WETH_ADDRESS

PAIR2_ADDRESS=$(cast call --rpc-url $L2_RPC_URL $FACTORY2_ADDRESS "getPair(address,address)" $TOKEN_ADDRESS $WETH_ADDRESS | cast parse-bytes32-address)
echo "PAIR2_ADDRESS=$PAIR2_ADDRESS" >> data/contracts/addresses.env
echo -e "${GREEN}✅ Second pair created at: $PAIR2_ADDRESS${NC}"

# Add liquidity to second pair (500K tokens + 5 ETH)
echo -e "${YELLOW}Adding liquidity to second pair (500K tokens + 5 ETH)...${NC}"

# Wrap 5 ETH to WETH
cast send --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY $WETH_ADDRESS "deposit()" --value 5000000000000000000

# Transfer tokens to second pair
cast send --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY $TOKEN_ADDRESS "transfer(address,uint256)" $PAIR2_ADDRESS 500000000000000000000000 # 500K tokens
cast send --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY $WETH_ADDRESS "transfer(address,uint256)" $PAIR2_ADDRESS 5000000000000000000 # 5 WETH

# Mint liquidity tokens for second pair
cast send --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY $PAIR2_ADDRESS "mint(address)" $DEPLOYER_ADDRESS

echo -e "${GREEN}✅ Liquidity added to second pair${NC}"

echo -e "${GREEN}✅ Uniswap V2 deployment complete!${NC}"
echo -e "${BLUE}📋 Uniswap V2 details:${NC}"
echo -e "  • WETH Address: $WETH_ADDRESS"
echo -e "  • Factory 1: $FACTORY1_ADDRESS"
echo -e "  • Factory 2: $FACTORY2_ADDRESS"
echo -e "  • Pair 1 (1M/10ETH): $PAIR1_ADDRESS"
echo -e "  • Pair 2 (500K/5ETH): $PAIR2_ADDRESS"