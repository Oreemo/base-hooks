// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {USDC} from "../src/USDC.sol";

contract USDCScript is Script {
    USDC public usdc;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        simpleToken = new SimpleToken(1000000000000000000000000000);

        vm.stopBroadcast();
    }
}
