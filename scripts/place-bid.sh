#!/bin/bash

# Script to place a bid on HooksPerpetualAuction contract
# This script calls the bid function with the specified parameters

set -e

# Load environment variables
source .env

# Contract addresses (update these with your actual deployed addresses)
AUCTION_CONTRACT="0x292Fd8c1fCFE109089FB38a1528379A1Fe6Cae72"
PAIR1_ADDRESS="0xd5Bf624C0c7192f13f5374070611D6f169bb5c88"
ARB_HOOK_ADDRESS="0x29a79095352a718B3D7Fe84E1F14E9F34A35598e" # Update with actual arb hook address

# Event signature for Uniswap V2 Swap event
SWAP_TOPIC0="0xd78ad95fa46c994b6551d0da85fc275fe613ce37657fb8d5e3d130840159d822"

# Bid parameters
FEE_PER_CALL="1000000000000000000" # 1 ETH in wei (high enough to not worry about funds)
CALLS_TO_DEPOSIT="100"
TOTAL_VALUE="100000000000000000000" # 100 ETH total value (FEE_PER_CALL * CALLS_TO_DEPOSIT)

# Builder RPC endpoint
RPC_URL="http://localhost:2222"

echo "Placing bid on HooksPerpetualAuction contract..."
echo "Auction Contract: $AUCTION_CONTRACT"
echo "Contract Address (Pair): $PAIR1_ADDRESS"
echo "Topic0 (Swap event): $SWAP_TOPIC0"
echo "Entrypoint (Arb Hook): $ARB_HOOK_ADDRESS"
echo "Fee per call: $FEE_PER_CALL wei"
echo "Calls to deposit: $CALLS_TO_DEPOSIT"
echo "Total value: $TOTAL_VALUE wei"
echo ""

# Call the bid function
cast send $AUCTION_CONTRACT \
    "bid(address,bytes32,address,uint256,uint256)" \
    $PAIR1_ADDRESS \
    $SWAP_TOPIC0 \
    $ARB_HOOK_ADDRESS \
    $FEE_PER_CALL \
    $CALLS_TO_DEPOSIT \
    --value $TOTAL_VALUE \
    --private-key $PRIVATE_KEY \
    --rpc-url $RPC_URL \
    --gas-limit 1000000

echo "Bid placed successfully!"

# Verify the bid by reading the hook data
echo ""
echo "Verifying bid..."
cast call $AUCTION_CONTRACT \
    "getHook(address,bytes32)" \
    $PAIR1_ADDRESS \
    $SWAP_TOPIC0 \
    --rpc-url $RPC_URL

echo ""
echo "Hook verification complete!"
