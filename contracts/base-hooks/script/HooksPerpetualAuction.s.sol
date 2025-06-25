// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {HooksPerpetualAuction} from "../src/HooksPerpetualAuction.sol";

contract HooksPerpetualAuctionScript is Script {
    HooksPerpetualAuction public hooksPerpetualAuction;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        hooksPerpetualAuction = new HooksPerpetualAuction();

        vm.stopBroadcast();
    }
}
