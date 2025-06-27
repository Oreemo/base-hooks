// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {UniswapV2Factory} from "../src/UniswapV2Factory.sol";
import {UniswapV2Router} from "../src/UniswapV2Router.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {UniswapV2Pair} from "../src/UniswapV2Pair.sol";
import {IWETH} from "../src/UniswapV2Router.sol";
import {WETH} from "solmate/tokens/WETH.sol";

contract TestUniswapV2Swap is Test {
    // UniswapV2Factory public factory;
    UniswapV2Router public router = UniswapV2Router(payable(0xe1Aa25618fA0c7A1CFDab5d6B456af611873b629));
    MockERC20 public token = MockERC20(payable(0xA15BB66138824a1c7167f5E85b957d04Dd34E468));
    WETH public weth = WETH(payable(0x4200000000000000000000000000000000000006));

    address public deployer = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720;

    // UniswapV2Factory public factory;
    // UniswapV2Router public router;
    // MockERC20 public token;
    // WETH public weth = WETH(payable(0x4200000000000000000000000000000000000006));

    function setUp() public {
        vm.createSelectFork("http://localhost:2222");
        vm.startPrank(deployer);

        // weth = new WETH();
        // factory = new UniswapV2Factory(address(this));
        // router = new UniswapV2Router(address(factory), address(weth));
        // token = new MockERC20("TestToken", "TT", 18);
        // token.mint(address(this), 1_000_000_000 ether);
        // token.approve(address(router), type(uint256).max);

        // address pool = factory.createPair(address(token), address(weth));

        // weth.deposit{value: 10 ether}();
        // token.transfer(pool, 1_000_000 ether);
        // weth.transfer(pool, 10 ether);
        // UniswapV2Pair(pool).mint(address(this));
    }

    function test_swapExactETHForTokens() public {
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(token);

        router.swapExactETHForTokens{value: 0.1 ether}(9000 ether, path, deployer, block.timestamp + 3600);
    }

    receive() external payable {}
}
