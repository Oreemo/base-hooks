// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {UniswapV2Factory} from "../src/UniswapV2Factory.sol";
import {UniswapV2Router, IWETH} from "../src/UniswapV2Router.sol";
import {UniswapV2Pair} from "../src/UniswapV2Pair.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UniswapV2FactoryScript is Script {
    UniswapV2Factory public factory;
    UniswapV2Router public router;

    address public constant WETH = 0x4200000000000000000000000000000000000006; // OP Stack system WETH

    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    address deployer = vm.addr(deployerPrivateKey);

    function run() external {
        vm.startBroadcast(deployerPrivateKey);

        factory = new UniswapV2Factory(deployer);
        router = new UniswapV2Router(address(factory), WETH);

        vm.stopBroadcast();

        // Log deployment info
        console.log("UniswapV2Factory deployed at:", address(factory));
        console.log("UniswapV2Router deployed at:", address(router));
        console.log("WETH address:", WETH);
        console.log("Deployer:", deployer);
    }

    function createPairAndAddLiquidity(address tokenA, uint256 amountA, uint256 amountETH) external {
        vm.startBroadcast(deployerPrivateKey);

        // Create pair
        address pair = factory.createPair(tokenA, WETH);
        console.log("Pair created at:", pair);

        IWETH(WETH).deposit{value: amountETH}();
        IERC20(tokenA).transfer(pair, amountA);
        IWETH(WETH).transfer(pair, amountETH);

        UniswapV2Pair(pair).mint(deployer);

        vm.stopBroadcast();

        console.log("Liquidity added - Token amount:", amountA);
        console.log("Liquidity added - ETH amount:", amountETH);
    }
}
