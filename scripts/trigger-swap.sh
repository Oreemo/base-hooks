#!/bin/bash

set -ex

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Triggering Uniswap V2 swap to generate Swap event...${NC}"

# Load environment variables
if [ -f ".env" ]; then
    source .env
fi

# Contract addresses from deployment
ADDRESSES_FILE="data/contracts/addresses.env"
if [ ! -f "$ADDRESSES_FILE" ]; then
    echo -e "${RED}❌ Contract addresses file not found. Please deploy contracts first with 'just deploy'${NC}"
    exit 1
fi

source "$ADDRESSES_FILE"

echo -e "${YELLOW}Contract addresses:${NC}"
echo -e "  • SimpleToken: $TOKEN_ADDRESS"
echo -e "  • UniswapV2Factory: $FACTORY1_ADDRESS"
echo -e "  • UniswapV2Router: $ROUTER1_ADDRESS"
echo -e "  • UniswapV2Pair: $PAIR1_ADDRESS"

# Network configuration
RPC_URL="http://localhost:2222"

# Get actual chain ID from RPC
CHAIN_ID=13
echo -e "  • Chain ID: $CHAIN_ID"

# User account (from builder-playground default accounts)
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
USER_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

# System WETH on OP Stack
WETH_ADDRESS="0x4200000000000000000000000000000000000006"

# Swap parameters - Using smaller amounts to avoid excessive price impact
# Current liquidity: 10 ETH + 1M SimpleTokens
# Router says 0.1 ETH should get us 9,871,580,343,970,612,988,504 wei (~9,871 tokens)
AMOUNT_IN="100000000000000000"          # 0.1 ETH in wei  
AMOUNT_OUT_MIN="9000000000000000000000" # Expect ~9,871 tokens, allow slippage to 9k
DEADLINE=$(($(date +%s) + 600))         # 10 minutes from now

echo -e "${YELLOW}Swap parameters:${NC}"
echo -e "  • Amount in: $AMOUNT_IN wei (0.1 ETH)"
echo -e "  • Amount out min: $AMOUNT_OUT_MIN wei (~9k tokens)"
echo -e "  • Token in: $WETH_ADDRESS (WETH)"
echo -e "  • Token out: $TOKEN_ADDRESS (SimpleToken)"
echo -e "  • Deadline: $DEADLINE"

# Check user ETH balance
echo -e "${YELLOW}Checking user balance...${NC}"
USER_BALANCE=$(cast balance $USER_ADDRESS --rpc-url $RPC_URL)
echo -e "  • User ETH balance: $USER_BALANCE wei"

# if [ "$USER_BALANCE" -lt "$AMOUNT_IN" ]; then
#     echo -e "${RED}❌ Insufficient ETH balance. Required: $AMOUNT_IN wei, Available: $USER_BALANCE wei${NC}"
#     exit 1
# fi

# Function to perform swap
perform_swap() {
    local amount_in=$1
    local token_in=$2
    local token_out=$3
    local router=$4
    local swap_type=$5

    echo -e "${YELLOW}Performing $swap_type swap...${NC}"

    if [ "$token_in" = "$WETH_ADDRESS" ]; then
        # ETH to Token swap
        echo -e "  • Swapping ETH for tokens..."
        SWAP_TX=$(cast send $router \
            "swapExactETHForTokens(uint256,address[],address,uint256)" \
            $AMOUNT_OUT_MIN \
            "[$WETH_ADDRESS,$token_out]" \
            $USER_ADDRESS \
            $DEADLINE \
            --value $amount_in \
            --private-key $PRIVATE_KEY \
            --rpc-url $RPC_URL \
            --chain-id $CHAIN_ID \
            --json | jq -r ".transactionHash")
    else
        # Token to ETH swap
        echo -e "  • Approving token spending..."
        # First approve the router to spend tokens
        APPROVE_TX=$(cast send $token_in \
            "approve(address,uint256)" \
            $router \
            $amount_in \
            --private-key $PRIVATE_KEY \
            --rpc-url $RPC_URL \
            --chain-id $CHAIN_ID \
            --json | jq -r ".transactionHash")

        echo -e "  • Approval transaction: $APPROVE_TX"

        # Wait a moment for approval to be mined
        sleep 2

        echo -e "  • Swapping tokens for ETH..."
        # TODO: fix amount out min for Token -> ETH swap
        SWAP_TX=$(cast send $router \
            "swapExactTokensForETH(uint256,uint256,address[],address,uint256)" \
            $amount_in \
            "0" \
            "[$token_in,$WETH_ADDRESS]" \
            $USER_ADDRESS \
            $DEADLINE \
            --private-key $PRIVATE_KEY \
            --rpc-url $RPC_URL \
            --chain-id $CHAIN_ID \
            --json | jq -r ".transactionHash")
    fi

    echo -e "  • Swap transaction: $SWAP_TX"

    # Wait for transaction to be mined
    echo -e "${YELLOW}Waiting for transaction to be mined...${NC}"
    cast receipt $SWAP_TX --rpc-url $RPC_URL >/dev/null 2>&1

    # Get transaction receipt to see the logs
    echo -e "${YELLOW}Transaction receipt:${NC}"
    RECEIPT=$(cast receipt $SWAP_TX --rpc-url $RPC_URL)
    echo "$RECEIPT"

    # Look for Swap events in the logs
    echo -e "${YELLOW}Looking for Swap events...${NC}"
    SWAP_EVENTS=$(echo "$RECEIPT" | grep -A 10 -B 2 "0xd78ad95fa46c994b6551d0da85fc275fe613ce37657fb8d5e3d130840159d822" || true)
    if [ -n "$SWAP_EVENTS" ]; then
        echo -e "${GREEN}✅ Swap event detected!${NC}"
        echo "$SWAP_EVENTS"
    else
        echo -e "${YELLOW}⚠️  No Swap event found in logs (this might be normal)${NC}"
    fi
}

# Perform ETH to Token swap
echo -e "${BLUE}=== ETH to SimpleToken Swap ===${NC}"
perform_swap $AMOUNT_IN $WETH_ADDRESS $TOKEN_ADDRESS $ROUTER1_ADDRESS "ETH→Token"

# Check token balance after swap
echo -e "${YELLOW}Checking token balance after swap...${NC}"
TOKEN_BALANCE=$(cast call $TOKEN_ADDRESS "balanceOf(address)" $USER_ADDRESS --rpc-url $RPC_URL)
echo -e "  • SimpleToken balance: $TOKEN_BALANCE"

# If we have tokens, perform reverse swap
if [ "$TOKEN_BALANCE" != "0x0000000000000000000000000000000000000000000000000000000000000000" ]; then
    echo -e "${BLUE}=== SimpleToken to ETH Swap ===${NC}"
    # Convert hex to decimal for the reverse swap
    TOKEN_AMOUNT_DEC=$(printf "%d" $TOKEN_BALANCE)
    perform_swap $TOKEN_AMOUNT_DEC $TOKEN_ADDRESS $WETH_ADDRESS $ROUTER1_ADDRESS "Token→ETH"
fi

echo -e "${GREEN}✅ Swap operations completed!${NC}"
echo -e "${BLUE}💡 Check the op-rbuilder logs to see if hooks were triggered:${NC}"
echo -e "  tail -f logs/rbuilder.log"
