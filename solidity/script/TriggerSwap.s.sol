// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {UniswapV2Router} from "../src/UniswapV2Router.sol";

contract TriggerSwap is Script {
    uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
    address deployer = vm.addr(deployerPrivateKey);

    address public constant WETH = 0x4200000000000000000000000000000000000006;

    function run(address _router, address token) public {
        vm.startBroadcast(deployerPrivateKey);

        UniswapV2Router router = UniswapV2Router(payable(_router));
        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(token);

        router.swapExactETHForTokens{value: 0.1 ether}(9000 ether, path, msg.sender, block.timestamp + 3600);
    }
}
