// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/UniswapV2Factory.sol";

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
}

contract UniswapV2Script is Script {
    UniswapV2Factory public factory;
    address public constant WETH = 0x4200000000000000000000000000000000000006; // OP Stack system WETH
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy Uniswap V2 Factory
        factory = new UniswapV2Factory(deployer);
        
        vm.stopBroadcast();
        
        // Log deployment info
        console.log("UniswapV2Factory deployed at:", address(factory));
        console.log("WETH address:", WETH);
        console.log("Deployer:", deployer);
    }
    
    function createPairAndAddLiquidity(
        address tokenA,
        uint256 amountA,
        uint256 amountETH
    ) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Create pair
        address pair = factory.createPair(tokenA, WETH);
        console.log("Pair created at:", pair);
        
        // Wrap ETH to WETH
        IWETH(WETH).deposit{value: amountETH}();
        
        // Transfer tokens to pair
        IERC20(tokenA).transfer(pair, amountA);
        IWETH(WETH).transfer(pair, amountETH);
        
        // Mint liquidity tokens
        UniswapV2Pair(pair).mint(deployer);
        
        vm.stopBroadcast();
        
        console.log("Liquidity added - Token amount:", amountA);
        console.log("Liquidity added - ETH amount:", amountETH);
    }
}