// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {USDT} from "../src/USDT.sol";

contract USDTScript is Script {
    USDT public usdt;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        simpleToken = new SimpleToken(1000000000000000000000000000);

        vm.stopBroadcast();
    }
}
