// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function kLast() external view returns (uint256);
}

interface IUniswapV2Router {
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        returns (uint256 amountOut);
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract UniswapV2ArbHook is Ownable, ReentrancyGuard {
    address public sequencer; // Address that can call onHook (usually the auction contract)

    struct DEXConfig {
        address router;
        string name;
        bool enabled;
    }

    mapping(address => DEXConfig) public dexConfigs;
    address[] public supportedDEXes;

    uint256 public minProfitThreshold = 0.0001 ether;
    uint256 public maxTradeSize = 10 ether;
    uint256 public gasCostBuffer = 0.01 ether; // Buffer for gas costs

    mapping(address => bool) public authorizedTokens;
    mapping(bytes32 => address) public pairRegistry; // Maps token pair hash to primary DEX pair address
    mapping(address => address) public pairToDEX; // Maps pair address to its DEX router

    event ArbitrageExecuted(
        address indexed primaryDEX,
        address indexed secondaryDEX,
        address indexed tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 profit
    );

    event ArbitrageSkipped(address indexed pair, string reason);

    event DEXAdded(address indexed router, string name);
    event DEXRemoved(address indexed router);

    error UnauthorizedCaller();
    error InvalidEventData();
    error InsufficientProfit();
    error ArbitrageFailed();
    error DEXNotSupported();
    error InvalidDEXConfig();

    constructor() Ownable(msg.sender) {}

    function setSequencer(address _sequencer) external onlyOwner {
        sequencer = _sequencer;
    }

    modifier onlySequencer() {
        if (msg.sender != sequencer) {
            revert UnauthorizedCaller();
        }
        _;
    }

    function addDEX(address router, string memory name) external onlyOwner {
        if (router == address(0) || bytes(name).length == 0) {
            revert InvalidDEXConfig();
        }

        if (bytes(dexConfigs[router].name).length == 0) {
            supportedDEXes.push(router);
        }

        dexConfigs[router] = DEXConfig({router: router, name: name, enabled: true});

        emit DEXAdded(router, name);
    }

    function removeDEX(address router) external onlyOwner {
        dexConfigs[router].enabled = false;

        for (uint256 i = 0; i < supportedDEXes.length; i++) {
            if (supportedDEXes[i] == router) {
                supportedDEXes[i] = supportedDEXes[supportedDEXes.length - 1];
                supportedDEXes.pop();
                break;
            }
        }

        emit DEXRemoved(router);
    }

    function setAuthorizedToken(address token, bool authorized) external onlyOwner {
        authorizedTokens[token] = authorized;
    }

    function setMinProfitThreshold(uint256 threshold) external onlyOwner {
        minProfitThreshold = threshold;
    }

    function setMaxTradeSize(uint256 size) external onlyOwner {
        maxTradeSize = size;
    }

    function setGasCostBuffer(uint256 buffer) external onlyOwner {
        gasCostBuffer = buffer;
    }

    function registerPair(address tokenA, address tokenB, address pairAddress, address dexRouter) external onlyOwner {
        bytes32 pairKey = _getPairKey(tokenA, tokenB);
        pairRegistry[pairKey] = pairAddress;
        pairToDEX[pairAddress] = dexRouter;
    }

    function _getPairKey(address tokenA, address tokenB) internal pure returns (bytes32) {
        return tokenA < tokenB ? keccak256(abi.encode(tokenA, tokenB)) : keccak256(abi.encode(tokenB, tokenA));
    }

    // Main hook function called by auction contract on Uniswap V2 Swap events
    function onHook(
        address contractAddr,
        bytes32 topic0,
        bytes32 topic1,
        bytes32 topic2,
        bytes32 topic3,
        bytes calldata eventData
    ) external onlySequencer {
        // Decode Uniswap V2 Swap event data
        // Event signature: Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to)
        // topic0 = keccak256("Swap(address,uint256,uint256,uint256,uint256,address)")
        // topic1 = indexed sender address
        // topic2 = indexed to address
        // topic3 = unused for this event (would be 0x0)

        // Extract indexed parameters from topics
        address sender = address(uint160(uint256(topic1))); // sender from topic1
        address to = address(uint160(uint256(topic2))); // to from topic2

        // eventData only contains the non-indexed parameters: amount0In, amount1In, amount0Out, amount1Out
        if (eventData.length < 128) {
            // 4 * 32 bytes for non-indexed params
            revert InvalidEventData();
        }

        (uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out) =
            abi.decode(eventData, (uint256, uint256, uint256, uint256));

        // Use the contractAddr as the pair address
        _checkArbitrageOpportunity(contractAddr, amount0In, amount1In, amount0Out, amount1Out);
    }

    function _checkArbitrageOpportunity(
        address pairAddress,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out
    ) internal {
        try this._executeArbitrageLogic(pairAddress, amount0In, amount1In, amount0Out, amount1Out) {
            // Arbitrage logic executed successfully
        } catch Error(string memory reason) {
            emit ArbitrageSkipped(pairAddress, reason);
        } catch {
            emit ArbitrageSkipped(pairAddress, "Unknown error");
        }
    }

    function _executeArbitrageLogic(
        address pairAddress,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out
    ) external nonReentrant {
        require(msg.sender == address(this), "Internal only");

        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        address token0 = pair.token0();
        address token1 = pair.token1();

        if (!authorizedTokens[token0] || !authorizedTokens[token1]) {
            revert("Unauthorized tokens");
        }

        // Determine swap direction and amounts
        address tokenIn;
        address tokenOut;
        uint256 amountIn;

        if (amount0In > 0 && amount1Out > 0) {
            tokenIn = token0;
            tokenOut = token1;
            amountIn = amount0In;
        } else if (amount1In > 0 && amount0Out > 0) {
            tokenIn = token1;
            tokenOut = token0;
            amountIn = amount1In;
        } else {
            revert("Invalid swap amounts");
        }

        if (amountIn > maxTradeSize) {
            amountIn = maxTradeSize;
        }

        // Find the DEX that executed this swap (primary DEX)
        address primaryDEX = _findDEXForPair(pairAddress);
        if (primaryDEX == address(0)) {
            revert("Primary DEX not found");
        }

        // Find best arbitrage opportunity on other DEXes
        (address bestSecondaryDEX, uint256 bestOutput, uint256 profit) =
            _findBestArbitrageOpportunity(tokenOut, tokenIn, amountIn, primaryDEX);

        if (profit < minProfitThreshold + gasCostBuffer) {
            revert InsufficientProfit();
        }

        uint256 balance = IERC20(tokenOut).balanceOf(address(this));
        if (balance == 0) {
            revert("No balance for arbitrage");
        }

        uint256 arbAmount = balance < amountIn ? balance : amountIn;

        _executeArbitrageSwap(bestSecondaryDEX, tokenOut, tokenIn, arbAmount, bestOutput);

        emit ArbitrageExecuted(primaryDEX, bestSecondaryDEX, tokenOut, tokenIn, arbAmount, profit);
    }

    function _findDEXForPair(address pairAddress) internal view returns (address) {
        // First check if we have a direct mapping for this pair
        address dexRouter = pairToDEX[pairAddress];
        if (dexRouter != address(0) && dexConfigs[dexRouter].enabled) {
            return dexRouter;
        }

        // Fallback: return the first enabled DEX as a default
        // In practice, you might want to query each DEX to find which one has this pair
        for (uint256 i = 0; i < supportedDEXes.length; i++) {
            if (dexConfigs[supportedDEXes[i]].enabled) {
                return supportedDEXes[i];
            }
        }
        return address(0);
    }

    function _findBestArbitrageOpportunity(address tokenIn, address tokenOut, uint256 amountIn, address excludeDEX)
        internal
        view
        returns (address bestDEX, uint256 bestOutput, uint256 profit)
    {
        bestOutput = 0;
        bestDEX = address(0);
        profit = 0;

        for (uint256 i = 0; i < supportedDEXes.length; i++) {
            address dexRouter = supportedDEXes[i];

            if (!dexConfigs[dexRouter].enabled || dexRouter == excludeDEX) {
                continue;
            }

            try this._getAmountOut(dexRouter, tokenIn, tokenOut, amountIn) returns (uint256 output) {
                if (output > bestOutput && output > amountIn) {
                    bestOutput = output;
                    bestDEX = dexRouter;
                    profit = output - amountIn;
                }
            } catch {
                // Skip this DEX if quotation fails
                continue;
            }
        }
    }

    function _getAmountOut(address router, address tokenIn, address tokenOut, uint256 amountIn)
        external
        view
        returns (uint256)
    {
        require(msg.sender == address(this), "Internal only");

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        uint256[] memory amounts = IUniswapV2Router(router).getAmountsOut(amountIn, path);
        return amounts[1];
    }

    function _executeArbitrageSwap(
        address router,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut
    ) internal {
        IERC20(tokenIn).approve(router, amountIn);

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        try IUniswapV2Router(router).swapExactTokensForTokens(
            amountIn, minAmountOut, path, address(this), block.timestamp + 300
        ) {
            // Swap successful
        } catch {
            revert ArbitrageFailed();
        }
    }

    // View functions for monitoring
    function getSupportedDEXCount() external view returns (uint256) {
        return supportedDEXes.length;
    }

    function getDEXInfo(address router) external view returns (DEXConfig memory) {
        return dexConfigs[router];
    }

    // Emergency functions
    function withdrawToken(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner(), amount);
    }

    function withdrawETH(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    receive() external payable {}
}
