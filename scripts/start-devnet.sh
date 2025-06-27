#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting OP Stack devnet with flashblocks...${NC}"

# Create necessary directories
mkdir -p data logs artifacts

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"
if ! command -v docker &>/dev/null; then
    echo -e "${RED}❌ Docker is required but not installed${NC}"
    exit 1
fi

if [ ! -f "./builder-playground/builder-playground" ]; then
    echo -e "${RED}❌ builder-playground not found. Please run 'just setup' first${NC}"
    exit 1
fi

if [ ! -d "./op-rbuilder" ]; then
    echo -e "${RED}❌ op-rbuilder repository not found. Please run 'just setup' first${NC}"
    exit 1
fi

# No manual configuration needed - playground mode auto-detects settings

echo -e "${YELLOW}Starting builder-playground OP Stack devnet with external builder...${NC}"
cd builder-playground
nohup go run main.go cook opstack --external-builder http://host.docker.internal:4444 --enable-latest-fork 0 >../logs/opstack.log 2>&1 &
OPSTACK_PID=$!
cd ..
echo $OPSTACK_PID >data/opstack.pid

# Wait for OP Stack to be ready
echo -e "${YELLOW}Waiting 5 seconds for OP Stack to initialize...${NC}"
sleep 5

# Check if opstack is running
if ! kill -0 $OPSTACK_PID 2>/dev/null; then
    echo -e "${RED}❌ OP Stack failed to start. Check logs/opstack.log${NC}"
    exit 1
fi

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

# Wait for services to be fully ready
echo -e "${YELLOW}Waiting 5 seconds for services to be ready...${NC}"
sleep 10

# Verify services are running
if ! kill -0 $OPSTACK_PID 2>/dev/null; then
    echo -e "${RED}❌ OP Stack process died${NC}"
    exit 1
fi

if ! kill -0 $RBUILDER_PID 2>/dev/null; then
    echo -e "${RED}❌ op-rbuilder process died${NC}"
    exit 1
fi

echo -e "${GREEN}✅ OP Stack devnet with flashblocks is running!${NC}"
echo -e "${BLUE}📊 Services:${NC}"
echo -e "  • OP Stack: PID $OPSTACK_PID (logs: logs/opstack.log)"
echo -e "  • op-rbuilder: PID $RBUILDER_PID (logs: logs/rbuilder.log)"
echo -e "  • Flashblocks endpoint: ws://localhost:8080"
echo -e "  • Builder RPC: http://localhost:2222"
echo -e "  • L2 RPC: http://localhost:8546"
echo -e "  • L1 RPC: http://localhost:8545" # builder-playground default

echo -e "${GREEN}🎉 Devnet is ready for use!${NC}"
echo -e "${BLUE}💡 To deploy contracts, run: just deploy${NC}"
