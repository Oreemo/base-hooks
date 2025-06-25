#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🎯 Deploying HooksPerpetualAuction...${NC}"

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

mkdir -p data/contracts

echo -e "${YELLOW}Deploying HooksPerpetualAuction to builder at $L2_RPC_URL...${NC}"

# Deploy HooksPerpetualAuction using forge script
cd contracts/base-hooks

# Use deterministic deployment if DETERMINISTIC flag is set
if [ "$DETERMINISTIC" = "true" ]; then
    echo -e "${YELLOW}Using deterministic deployment with CREATE2...${NC}"

    # Try to deploy first and handle collision if it occurs
    DEPLOYMENT_OUTPUT=$(forge script script/HooksPerpetualAuctionDeterministic.s.sol:HooksPerpetualAuctionDeterministicScript --rpc-url $L2_RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --broadcast 2>&1 || true)

    # Check if deployment was successful (extract from console logs)
    HOOKS_ADDRESS=$(echo "$DEPLOYMENT_OUTPUT" | grep "deployed to address:" | grep -o '0x[a-fA-F0-9]\{40\}' | head -1)

    if [ -n "$HOOKS_ADDRESS" ]; then
        echo -e "${GREEN}✅ Contract deployed at: $HOOKS_ADDRESS${NC}"
    else
        # Deployment failed, check if it's due to CreateCollision
        if echo "$DEPLOYMENT_OUTPUT" | grep -q "CreateCollision"; then
            echo -e "${YELLOW}⚠️  CreateCollision detected - contract already deployed${NC}"

            # Extract the address directly from the trace output
            # Look for pattern: "→ new <unknown>@0x..." right before "CreateCollision"
            COLLISION_ADDRESS=$(echo "$DEPLOYMENT_OUTPUT" | grep -B1 "CreateCollision" | grep "→ new <unknown>@" | grep -o '0x[a-fA-F0-9]\{40\}' | head -1)

            if [ -n "$COLLISION_ADDRESS" ]; then
                echo -e "${BLUE}Extracted address from collision trace: $COLLISION_ADDRESS${NC}"

                # Verify contract exists at that address
                BYTECODE=$(cast code --rpc-url $L2_RPC_URL $COLLISION_ADDRESS)
                if [ "$BYTECODE" != "0x" ]; then
                    HOOKS_ADDRESS=$COLLISION_ADDRESS
                    echo -e "${GREEN}✅ Using existing contract at: $HOOKS_ADDRESS${NC}"
                else
                    echo -e "${RED}❌ No contract found at collision address${NC}"
                    exit 1
                fi
            else
                echo -e "${RED}❌ Could not extract address from collision trace${NC}"
                echo -e "${YELLOW}Deployment output:${NC}"
                echo "$DEPLOYMENT_OUTPUT"
                exit 1
            fi
        else
            # Other deployment error
            echo -e "${RED}❌ Deployment failed with error:${NC}"
            echo "$DEPLOYMENT_OUTPUT"
            exit 1
        fi
    fi
else
    echo -e "${YELLOW}Using standard deployment...${NC}"
    HOOKS_ADDRESS=$(PRIVATE_KEY=$DEPLOYER_PRIVATE_KEY forge script script/HooksPerpetualAuction.s.sol:HooksPerpetualAuctionScript --rpc-url $L2_RPC_URL --broadcast --json | jq -rc 'select(.contract_address) | .contract_address')
fi

if [ -z "$HOOKS_ADDRESS" ] || [ "$HOOKS_ADDRESS" = "null" ]; then
    echo -e "${RED}❌ Failed to deploy HooksPerpetualAuction${NC}"
    exit 1
fi

cd ../..
echo "HOOKS_ADDRESS=$HOOKS_ADDRESS" >>data/contracts/addresses.env
echo -e "${GREEN}✅ HooksPerpetualAuction deployed at: $HOOKS_ADDRESS${NC}"

# Get contract details
echo -e "${YELLOW}Fetching contract details...${NC}"
EXCESS_ETH=$(cast call --rpc-url $L2_RPC_URL $HOOKS_ADDRESS "getExcessETH()")

echo -e "${GREEN}✅ HooksPerpetualAuction deployment complete!${NC}"
echo -e "${BLUE}📋 HooksPerpetualAuction details:${NC}"
echo -e "  • Contract Address: $HOOKS_ADDRESS"
echo -e "  • Owner: $DEPLOYER_ADDRESS"
echo -e "  • ExcessETH: $EXCESS_ETH%"
