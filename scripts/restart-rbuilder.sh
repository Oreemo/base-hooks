#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔄 Building and restarting op-rbuilder...${NC}"

# Check if op-rbuilder directory exists
if [ ! -d "./op-rbuilder" ]; then
    echo -e "${RED}❌ op-rbuilder repository not found. Please run 'just setup' first${NC}"
    exit 1
fi

# Stop existing op-rbuilder process
if [ -f "data/rbuilder.pid" ]; then
    RBUILDER_PID=$(cat data/rbuilder.pid)
    if kill -0 $RBUILDER_PID 2>/dev/null; then
        echo -e "${YELLOW}Stopping existing op-rbuilder (PID: $RBUILDER_PID)...${NC}"
        kill $RBUILDER_PID
        sleep 2
        if kill -0 $RBUILDER_PID 2>/dev/null; then
            echo -e "${YELLOW}Force killing op-rbuilder...${NC}"
            kill -9 $RBUILDER_PID
        fi
    fi
    rm -f data/rbuilder.pid
fi

# Kill any remaining op-rbuilder processes
pkill -f "op-rbuilder" || true

# Start op-rbuilder
echo -e "${YELLOW}Starting op-rbuilder with flashblocks...${NC}"
cd op-rbuilder
nohup cargo run -p op-rbuilder --bin op-rbuilder -- node \
    --chain $HOME/.playground/devnet/l2-genesis.json \
    --http \
    --http.port 2222 \
    --http.api admin,debug,eth,net,trace,txpool,web3,rpc,miner,flashbots,reth \
    --authrpc.addr 0.0.0.0 \
    --authrpc.port 4444 \
    --authrpc.jwtsecret $HOME/.playground/devnet/jwtsecret \
    --port 30333 \
    --disable-discovery \
    --metrics 127.0.0.1:9011 \
    --rollup.builder-secret-key ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
    --trusted-peers enode://79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8@127.0.0.1:30304 \
    --flashblocks.enabled \
    --flashblocks.port 8080 \
    --flashblocks.addr 0.0.0.0 \
    >../logs/rbuilder.log 2>&1 &
RBUILDER_PID=$!
cd ..
echo $RBUILDER_PID >data/rbuilder.pid

# Wait for service to be ready
echo -e "${YELLOW}Waiting 5 seconds for op-rbuilder to be ready...${NC}"
sleep 2

# Verify service is running
if ! kill -0 $RBUILDER_PID 2>/dev/null; then
    echo -e "${RED}❌ op-rbuilder process died. Check logs/rbuilder.log${NC}"
    exit 1
fi

echo -e "${GREEN}✅ op-rbuilder built and restarted successfully!${NC}"
echo -e "${BLUE}📊 Service info:${NC}"
echo -e "  • op-rbuilder: PID $RBUILDER_PID (logs: logs/rbuilder.log)"
echo -e "  • Flashblocks endpoint: ws://localhost:8080"
echo -e "  • Builder RPC: http://localhost:2222"
