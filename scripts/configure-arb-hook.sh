#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}⚙️  Configuring UniswapV2ArbHook...${NC}"

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

# Load contract addresses
if [ ! -f data/contracts/addresses.env ]; then
    echo -e "${RED}❌ Contract addresses file not found${NC}"
    echo -e "${YELLOW}Please deploy contracts first using: just deploy${NC}"
    exit 1
fi

source data/contracts/addresses.env

# Check required addresses
if [ -z "$ARB_HOOK_ADDRESS" ] || [ -z "$HOOKS_ADDRESS" ] || [ -z "$ROUTER1_ADDRESS" ] || [ -z "$ROUTER2_ADDRESS" ] || [ -z "$TOKEN_ADDRESS" ] || [ -z "$WETH_ADDRESS" ] || [ -z "$PAIR1_ADDRESS" ] || [ -z "$PAIR2_ADDRESS" ]; then
    echo -e "${RED}❌ Required contract addresses not found${NC}"
    echo -e "${YELLOW}Missing addresses - please ensure all contracts are deployed${NC}"
    exit 1
fi

echo -e "${YELLOW}Configuring UniswapV2ArbHook at: $ARB_HOOK_ADDRESS${NC}"

# 1. Set sequencer to HooksPerpetualAuction contract
echo -e "${YELLOW}Setting sequencer to HooksPerpetualAuction...${NC}"
cast send --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY $ARB_HOOK_ADDRESS "setSequencer(address)" $HOOKS_ADDRESS

# 2. Add supported DEXes (Router 1 and Router 2)
echo -e "${YELLOW}Adding DEX 1 (Router 1)...${NC}"
cast send --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY $ARB_HOOK_ADDRESS "addDEX(address,string)" $ROUTER1_ADDRESS "UniswapV2-DEX1"

echo -e "${YELLOW}Adding DEX 2 (Router 2)...${NC}"
cast send --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY $ARB_HOOK_ADDRESS "addDEX(address,string)" $ROUTER2_ADDRESS "UniswapV2-DEX2"

# 3. Authorize tokens for arbitrage
echo -e "${YELLOW}Authorizing TOKEN for arbitrage...${NC}"
cast send --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY $ARB_HOOK_ADDRESS "setAuthorizedToken(address,bool)" $TOKEN_ADDRESS true

echo -e "${YELLOW}Authorizing WETH for arbitrage...${NC}"
cast send --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY $ARB_HOOK_ADDRESS "setAuthorizedToken(address,bool)" $WETH_ADDRESS true

# 4. Register trading pairs with their respective DEXes
echo -e "${YELLOW}Registering Pair 1 with Router 1...${NC}"
cast send --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY $ARB_HOOK_ADDRESS "registerPair(address,address,address,address)" $TOKEN_ADDRESS $WETH_ADDRESS $PAIR1_ADDRESS $ROUTER1_ADDRESS

echo -e "${YELLOW}Registering Pair 2 with Router 2...${NC}"
cast send --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY $ARB_HOOK_ADDRESS "registerPair(address,address,address,address)" $TOKEN_ADDRESS $WETH_ADDRESS $PAIR2_ADDRESS $ROUTER2_ADDRESS

# 5. Set arbitrage parameters
echo -e "${YELLOW}Setting min profit threshold to 0.001 ETH...${NC}"
cast send --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY $ARB_HOOK_ADDRESS "setMinProfitThreshold(uint256)" 1000000000000000 # 0.001 ETH

echo -e "${YELLOW}Setting max trade size to 5 ETH...${NC}"
cast send --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY $ARB_HOOK_ADDRESS "setMaxTradeSize(uint256)" 5000000000000000000 # 5 ETH

echo -e "${YELLOW}Setting gas cost buffer to 0.005 ETH...${NC}"
cast send --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY $ARB_HOOK_ADDRESS "setGasCostBuffer(uint256)" 5000000000000000 # 0.005 ETH

# 6. Provide some initial token balance to the arbitrage contract for testing
echo -e "${YELLOW}Providing initial token balance for arbitrage...${NC}"
cast send --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY $TOKEN_ADDRESS "transfer(address,uint256)" $ARB_HOOK_ADDRESS 100000000000000000000000 # 100K tokens

# 7. Provide some ETH balance for arbitrage
echo -e "${YELLOW}Providing initial ETH balance for arbitrage...${NC}"
cast send --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --value 1000000000000000000 $ARB_HOOK_ADDRESS "0x" # 1 ETH

# Get current configuration
echo -e "${YELLOW}Fetching current configuration...${NC}"

SEQUENCER=$(cast call --rpc-url $L2_RPC_URL $ARB_HOOK_ADDRESS "sequencer()")
DEX_COUNT=$(cast call --rpc-url $L2_RPC_URL $ARB_HOOK_ADDRESS "getSupportedDEXCount()")
DEX_COUNT_DEC=$(cast to-dec $DEX_COUNT)

MIN_PROFIT=$(cast call --rpc-url $L2_RPC_URL $ARB_HOOK_ADDRESS "minProfitThreshold()")
MIN_PROFIT_DEC=$(cast to-dec $MIN_PROFIT)
MIN_PROFIT_ETH=$(echo "scale=6; $MIN_PROFIT_DEC / 1000000000000000000" | bc -l)

MAX_TRADE=$(cast call --rpc-url $L2_RPC_URL $ARB_HOOK_ADDRESS "maxTradeSize()")
MAX_TRADE_DEC=$(cast to-dec $MAX_TRADE)
MAX_TRADE_ETH=$(echo "scale=0; $MAX_TRADE_DEC / 1000000000000000000" | bc -l)

GAS_BUFFER=$(cast call --rpc-url $L2_RPC_URL $ARB_HOOK_ADDRESS "gasCostBuffer()")
GAS_BUFFER_DEC=$(cast to-dec $GAS_BUFFER)
GAS_BUFFER_ETH=$(echo "scale=6; $GAS_BUFFER_DEC / 1000000000000000000" | bc -l)

TOKEN_AUTHORIZED=$(cast call --rpc-url $L2_RPC_URL $ARB_HOOK_ADDRESS "authorizedTokens(address)" $TOKEN_ADDRESS)
WETH_AUTHORIZED=$(cast call --rpc-url $L2_RPC_URL $ARB_HOOK_ADDRESS "authorizedTokens(address)" $WETH_ADDRESS)

# Check token balances
TOKEN_BALANCE=$(cast call --rpc-url $L2_RPC_URL $TOKEN_ADDRESS "balanceOf(address)" $ARB_HOOK_ADDRESS)
TOKEN_BALANCE_DEC=$(cast to-dec $TOKEN_BALANCE)
TOKEN_BALANCE_FORMATTED=$(echo "scale=0; $TOKEN_BALANCE_DEC / 1000000000000000000" | bc -l)

ETH_BALANCE=$(cast balance --rpc-url $L2_RPC_URL $ARB_HOOK_ADDRESS)
ETH_BALANCE_FORMATTED=$(echo "scale=3; $ETH_BALANCE / 1000000000000000000" | bc -l)

echo -e "${GREEN}✅ UniswapV2ArbHook configuration complete!${NC}"
echo -e "${BLUE}📋 UniswapV2ArbHook details:${NC}"
echo -e "  • Contract Address: $ARB_HOOK_ADDRESS"
echo -e "  • Owner: $DEPLOYER_ADDRESS"
echo -e "  • Sequencer: $SEQUENCER"
echo -e "  • Supported DEXes: $DEX_COUNT_DEC"
echo -e "  • Min Profit Threshold: $MIN_PROFIT_ETH ETH"
echo -e "  • Max Trade Size: $MAX_TRADE_ETH ETH"
echo -e "  • Gas Cost Buffer: $GAS_BUFFER_ETH ETH"
echo -e "  • TOKEN Authorized: $TOKEN_AUTHORIZED"
echo -e "  • WETH Authorized: $WETH_AUTHORIZED"
echo -e "  • TOKEN Balance: $TOKEN_BALANCE_FORMATTED tokens"
echo -e "  • ETH Balance: $ETH_BALANCE_FORMATTED ETH"

echo -e "${BLUE}📋 Registered Pairs:${NC}"
echo -e "  • Pair 1: $PAIR1_ADDRESS → Router 1: $ROUTER1_ADDRESS"
echo -e "  • Pair 2: $PAIR2_ADDRESS → Router 2: $ROUTER2_ADDRESS"
