#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}⚙️  Setting up OP Stack devnet prerequisites...${NC}"

# Check if running on macOS or Linux
OS="$(uname -s)"
case "${OS}" in
Linux*) MACHINE=Linux ;;
Darwin*) MACHINE=Mac ;;
*) MACHINE="UNKNOWN:${OS}" ;;
esac

echo -e "${YELLOW}Detected OS: $MACHINE${NC}"

# Check and install Docker
if ! command -v docker &>/dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    echo -e "${YELLOW}Please install Docker from: https://docs.docker.com/get-docker/${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Docker is installed${NC}"
fi

# Check if Docker is running
if ! docker info &>/dev/null; then
    echo -e "${RED}❌ Docker is not running${NC}"
    echo -e "${YELLOW}Please start Docker and try again${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Docker is running${NC}"
fi

# Check and install Go
if ! command -v go &>/dev/null; then
    echo -e "${RED}❌ Go is not installed${NC}"
    echo -e "${YELLOW}Installing Go...${NC}"

    if [ "$MACHINE" = "Mac" ]; then
        if command -v brew &>/dev/null; then
            brew install go
        else
            echo -e "${RED}Homebrew not found. Please install Go manually from: https://golang.org/dl/${NC}"
            exit 1
        fi
    elif [ "$MACHINE" = "Linux" ]; then
        # Download and install Go for Linux
        GO_VERSION="1.21.0"
        wget -q -O go.tar.gz "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf go.tar.gz
        rm go.tar.gz

        # Add Go to PATH if not already there
        if ! echo "$PATH" | grep -q "/usr/local/go/bin"; then
            echo 'export PATH=$PATH:/usr/local/go/bin' >>~/.bashrc
            export PATH=$PATH:/usr/local/go/bin
        fi
    fi
else
    echo -e "${GREEN}✅ Go is installed ($(go version))${NC}"
fi

# Check and install Rust
if ! command -v cargo &>/dev/null; then
    echo -e "${RED}❌ Rust is not installed${NC}"
    echo -e "${YELLOW}Installing Rust...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
else
    echo -e "${GREEN}✅ Rust is installed ($(rustc --version))${NC}"
fi

# Check and install Foundry (cast, forge, etc.)
if ! command -v cast &>/dev/null; then
    echo -e "${RED}❌ Foundry is not installed${NC}"
    echo -e "${YELLOW}Installing Foundry...${NC}"
    curl -L https://foundry.paradigm.xyz | bash
    source ~/.bashrc
    foundryup
else
    echo -e "${GREEN}✅ Foundry is installed ($(cast --version | head -1))${NC}"
fi

# Clone op-rbuilder repository
if [ ! -d "op-rbuilder" ]; then
    echo -e "${YELLOW}Cloning op-rbuilder repository...${NC}"
    git clone https://github.com/0x00101010/op-rbuilder.git
else
    echo -e "${GREEN}✅ op-rbuilder repository exists${NC}"
fi

# op-rbuilder cloned - will build on first run

# Clone builder-playground repository
if [ ! -d "builder-playground" ]; then
    echo -e "${YELLOW}Cloning builder-playground repository...${NC}"
    git clone https://github.com/flashbots/builder-playground.git
else
    echo -e "${GREEN}✅ builder-playground repository exists${NC}"
fi

# Build builder-playground
echo -e "${YELLOW}Building builder-playground...${NC}"
cd builder-playground
go build -o builder-playground main.go
cd ..

# Install bc for calculations
if ! command -v bc &>/dev/null; then
    echo -e "${YELLOW}Installing bc for calculations...${NC}"
    if [ "$MACHINE" = "Mac" ]; then
        brew install bc
    elif [ "$MACHINE" = "Linux" ]; then
        sudo apt update && sudo apt install -y bc
    fi
else
    echo -e "${GREEN}✅ bc is installed${NC}"
fi

# Create necessary directories
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p data logs artifacts

echo -e "${GREEN}🎉 Setup complete!${NC}"
echo -e "${BLUE}You can now run: just start${NC}"
