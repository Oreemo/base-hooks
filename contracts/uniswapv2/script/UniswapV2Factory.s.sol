// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/UniswapV2Factory.sol";

contract UniswapV2FactoryScript is Script {
    UniswapV2Factory public factory;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy Uniswap V2 Factory
        factory = new UniswapV2Factory(deployer);
        
        vm.stopBroadcast();
        
        // Log deployment info
        console.log("UniswapV2Factory deployed at:", address(factory));
        console.log("Deployer:", deployer);
    }
}