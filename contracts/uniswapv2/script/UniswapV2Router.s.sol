// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/UniswapV2Router02.sol";

contract UniswapV2RouterScript is Script {
    UniswapV2Router02 public router;
    address public constant WETH = 0x4200000000000000000000000000000000000006; // OP Stack system WETH
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address factoryAddress = vm.envAddress("FACTORY_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy Uniswap V2 Router
        router = new UniswapV2Router02(factoryAddress, WETH);
        
        vm.stopBroadcast();
        
        // Log deployment info
        console.log("UniswapV2Router02 deployed at:", address(router));
        console.log("Factory address:", factoryAddress);
        console.log("WETH address:", WETH);
        console.log("Deployer:", deployer);
    }
}