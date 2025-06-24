#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🛑 Stopping OP Stack devnet...${NC}"

# Stop processes using PID files
if [ -f "data/opstack.pid" ]; then
    OPSTACK_PID=$(cat data/opstack.pid)
    if kill -0 $OPSTACK_PID 2>/dev/null; then
        echo -e "${YELLOW}Stopping OP Stack (PID: $OPSTACK_PID)...${NC}"
        kill $OPSTACK_PID
        sleep 2
        if kill -0 $OPSTACK_PID 2>/dev/null; then
            echo -e "${YELLOW}Force killing OP Stack...${NC}"
            kill -9 $OPSTACK_PID
        fi
    fi
    rm -f data/opstack.pid
fi

if [ -f "data/rbuilder.pid" ]; then
    RBUILDER_PID=$(cat data/rbuilder.pid)
    if kill -0 $RBUILDER_PID 2>/dev/null; then
        echo -e "${YELLOW}Stopping op-rbuilder (PID: $RBUILDER_PID)...${NC}"
        kill $RBUILDER_PID
        sleep 2
        if kill -0 $RBUILDER_PID 2>/dev/null; then
            echo -e "${YELLOW}Force killing op-rbuilder...${NC}"
            kill -9 $RBUILDER_PID
        fi
    fi
    rm -f data/rbuilder.pid
fi

# Kill any remaining processes
echo -e "${YELLOW}Killing any remaining processes...${NC}"
pkill -f "builder-playground" || true
pkill -f "op-rbuilder" || true
pkill -f "op-node" || true
pkill -f "op-geth" || true

# Stop Docker containers
echo -e "${YELLOW}Stopping Docker containers...${NC}"
docker stop $(docker ps -q --filter "name=op-stack" --filter "name=rbuilder" --filter "name=builder-playground") 2>/dev/null || true

echo -e "${GREEN}✅ Devnet stopped successfully!${NC}"