// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";

import {HooksPerpetualAuction} from "../src/HooksPerpetualAuction.sol";

contract HooksPerpetualAuctionDeterministicScript is Script {
    HooksPerpetualAuction public hooksPerpetualAuction;

    // Use a different salt to avoid collision with existing deployment
    function generateSalt() internal pure returns (bytes32) {
        // Use a different version to avoid collision with any previous deployments
        return keccak256(abi.encodePacked("HooksPerpetualAuction_v1.0.0"));
    }

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Generate dynamic salt to avoid collisions
        bytes32 salt = generateSalt();

        // Deploy using CREATE2 for deterministic address
        hooksPerpetualAuction = new HooksPerpetualAuction{salt: salt}();

        // Log the deployment details
        console.log("HooksPerpetualAuction deployed to address:", address(hooksPerpetualAuction));
        console.log("Salt used:", vm.toString(salt));
        console.log("Block timestamp:", block.timestamp);

        vm.stopBroadcast();
    }
}
