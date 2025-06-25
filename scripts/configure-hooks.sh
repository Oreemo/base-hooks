#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}⚙️  Configuring HooksPerpetualAuction...${NC}"

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

if [ -z "$HOOKS_ADDRESS" ]; then
    echo -e "${RED}❌ HooksPerpetualAuction address not found${NC}"
    exit 1
fi

echo -e "${YELLOW}Configuring HooksPerpetualAuction at: $HOOKS_ADDRESS${NC}"

# # Configure originator share (20% = 2000 basis points)
# echo -e "${YELLOW}Setting originator share to 20%...${NC}"
# cast send --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY $HOOKS_ADDRESS "setOriginatorShare(uint256)" 2000

# # Configure hook gas stipend (1M gas)
# echo -e "${YELLOW}Setting hook gas stipend to 1M gas...${NC}"
# cast send --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY $HOOKS_ADDRESS "setHookGasStipend(uint256)" 1000000

# Get current configuration
echo -e "${YELLOW}Fetching current configuration...${NC}"
ORIGINATOR_SHARE=$(cast call --rpc-url $L2_RPC_URL $HOOKS_ADDRESS "originatorShareBps()")
echo $ORIGINATOR_SHARE
ORIGINATOR_SHARE_DEC=$(cast to-dec $ORIGINATOR_SHARE)
ORIGINATOR_SHARE_PCT=$(echo "scale=1; $ORIGINATOR_SHARE_DEC / 100" | bc -l)

GAS_STIPEND=$(cast call --rpc-url $L2_RPC_URL $HOOKS_ADDRESS "hookGasStipend()")
GAS_STIPEND_DEC=$(cast to-dec $GAS_STIPEND)

MIN_CALLS=$(cast call --rpc-url $L2_RPC_URL $HOOKS_ADDRESS "MIN_CALLS_DEPOSIT()")
MIN_CALLS_DEC=$(cast to-dec $MIN_CALLS)

TOTAL_RESERVED=$(cast call --rpc-url $L2_RPC_URL $HOOKS_ADDRESS "totalReservedETH()")
TOTAL_RESERVED_DEC=$(cast to-dec $TOTAL_RESERVED)
TOTAL_RESERVED_ETH=$(echo "scale=4; $TOTAL_RESERVED_DEC / 1000000000000000000" | bc -l)

EXCESS_ETH=$(cast call --rpc-url $L2_RPC_URL $HOOKS_ADDRESS "getExcessETH()")
EXCESS_ETH_DEC=$(cast to-dec $EXCESS_ETH)
EXCESS_ETH_FORMATTED=$(echo "scale=4; $EXCESS_ETH_DEC / 1000000000000000000" | bc -l)

echo -e "${GREEN}✅ HooksPerpetualAuction configuration complete!${NC}"
echo -e "${BLUE}📋 HooksPerpetualAuction details:${NC}"
echo -e "  • Contract Address: $HOOKS_ADDRESS"
echo -e "  • Owner: $DEPLOYER_ADDRESS"
echo -e "  • Originator Share: $ORIGINATOR_SHARE_PCT%"
echo -e "  • Hook Gas Stipend: $GAS_STIPEND_DEC gas"
echo -e "  • Min Calls Deposit: $MIN_CALLS_DEC calls"
echo -e "  • Total Reserved ETH: $TOTAL_RESERVED_ETH ETH"
echo -e "  • Excess ETH Available: $EXCESS_ETH_FORMATTED ETH"
