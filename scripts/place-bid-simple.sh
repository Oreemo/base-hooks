#!/bin/bash

# Simple script to place a bid on HooksPerpetualAuction for Uniswap V2 Swap events
# Run this after starting the devnet with: just start

set -e

# Load environment if it exists
if [ -f .env ]; then
    source .env
fi

# Contract addresses - update these based on your deployment
AUCTION_CONTRACT="0x292Fd8c1fCFE109089FB38a1528379A1Fe6Cae72"
PAIR1_ADDRESS="0x29a79095352a718B3D7Fe84E1F14E9F34A35598e"     # Update with actual pair address
ARB_HOOK_ADDRESS="0x29a79095352a718B3D7Fe84E1F14E9F34A35598e"  # Update with actual arb hook address

# Uniswap V2 Swap event signature hash
SWAP_TOPIC0="0xd78ad95fa46c994b6551d0da85fc275fe613ce37657fb8d5e3d130840159d822"

# Bid parameters
FEE_PER_CALL="1000000000000000000"    # 1 ETH per call (in wei)
CALLS_TO_DEPOSIT="100"                # 100 calls
TOTAL_VALUE="100000000000000000000"   # 100 ETH total (1 ETH * 100 calls)

# Network settings
RPC_URL="http://localhost:2222"
PRIVATE_KEY="${PRIVATE_KEY:-0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6}"

echo "🎯 Placing bid on HooksPerpetualAuction..."
echo "📍 Auction Contract: $AUCTION_CONTRACT"
echo "📍 Target Contract: $PAIR1_ADDRESS"
echo "📍 Entrypoint: $ARB_HOOK_ADDRESS"
echo "💰 Fee per call: $FEE_PER_CALL wei (1 ETH)"
echo "🔢 Calls to deposit: $CALLS_TO_DEPOSIT"
echo "💸 Total value: $TOTAL_VALUE wei (100 ETH)"
echo ""

# Check if we have enough balance
echo "🔍 Checking account balance..."
BALANCE=$(cast balance $(cast wallet address --private-key $PRIVATE_KEY) --rpc-url $RPC_URL)
echo "💰 Account balance: $BALANCE wei"

if [ "$BALANCE" -lt "$TOTAL_VALUE" ]; then
    echo "❌ Insufficient balance! Need at least $TOTAL_VALUE wei"
    exit 1
fi

echo "✅ Sufficient balance, proceeding with bid..."
echo ""

# Place the bid
echo "📤 Sending bid transaction..."
RESULT=$(cast send $AUCTION_CONTRACT \
    "bid(address,bytes32,address,uint256,uint256)" \
    $PAIR1_ADDRESS \
    $SWAP_TOPIC0 \
    $ARB_HOOK_ADDRESS \
    $FEE_PER_CALL \
    $CALLS_TO_DEPOSIT \
    --value $TOTAL_VALUE \
    --private-key $PRIVATE_KEY \
    --rpc-url $RPC_URL \
    --gas-limit 1000000 \
    --json)

echo "✅ Transaction sent!"
echo "📋 Result: $RESULT"
echo ""

# Wait a moment for transaction to be mined
sleep 2

# Verify the bid
echo "🔍 Verifying bid was placed..."
HOOK_DATA=$(cast call $AUCTION_CONTRACT \
    "getHook(address,bytes32)" \
    $PAIR1_ADDRESS \
    $SWAP_TOPIC0 \
    --rpc-url $RPC_URL)

echo "📊 Hook data: $HOOK_DATA"

# Parse and display hook information in a readable format
echo ""
echo "🎉 Bid verification:"
echo "📍 Owner: $(echo $HOOK_DATA | cut -d',' -f1)"
echo "📍 Entrypoint: $(echo $HOOK_DATA | cut -d',' -f2)"
echo "💰 Fee per call: $(echo $HOOK_DATA | cut -d',' -f3) wei"
echo "💸 Deposit: $(echo $HOOK_DATA | cut -d',' -f4) wei"
echo "🔢 Calls remaining: $(echo $HOOK_DATA | cut -d',' -f5)"

echo ""
echo "🎊 Bid successfully placed! The hook will now execute on Uniswap V2 Swap events."