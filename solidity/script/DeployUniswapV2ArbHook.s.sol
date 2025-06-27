// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {UniswapV2ArbHook} from "../src/UniswapV2ArbHook.sol";

contract UniswapV2ArbHookScript is Script {
    UniswapV2ArbHook public arbHook;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy UniswapV2ArbHook
        arbHook = new UniswapV2ArbHook();

        vm.stopBroadcast();

        // Log deployment info
        console.log("UniswapV2ArbHook deployed at:", address(arbHook));
        console.log("Sequencer (initially unset):", arbHook.sequencer());
        console.log("Min profit threshold:", arbHook.minProfitThreshold());
        console.log("Max trade size:", arbHook.maxTradeSize());
    }
}
