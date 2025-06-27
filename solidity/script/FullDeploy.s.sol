// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {UniswapV2Factory} from "../src/UniswapV2Factory.sol";
import {UniswapV2Router, IWETH} from "../src/UniswapV2Router.sol";
import {UniswapV2Pair} from "../src/UniswapV2Pair.sol";
import {HooksPerpetualAuction} from "../src/HooksPerpetualAuction.sol";
import {UniswapV2ArbHook} from "../src/UniswapV2ArbHook.sol";

contract FullDeploy is Script {
    uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
    address deployer = vm.addr(deployerPrivateKey);

    address public constant WETH = 0x4200000000000000000000000000000000000006;

    MockERC20 public token;
    UniswapV2Factory public factory1;
    UniswapV2Router public router1;
    UniswapV2Pair public pair1;
    UniswapV2Factory public factory2;
    UniswapV2Router public router2;
    UniswapV2Pair public pair2;
    HooksPerpetualAuction public hooksPerpetualAuction;
    UniswapV2ArbHook public arbHook;

    function run() public {
        vm.startBroadcast(deployerPrivateKey);

        _deployMockToken();
        // deploy first instance, add 1M token + 10 ETH as liquidity
        (factory1, router1, pair1) = _deployUniswapV2Instance(1_000_000 ether, 10 ether);
        // deploy second instance, add 500k token + 5 ETH as liquidity
        (factory2, router2, pair2) = _deployUniswapV2Instance(500_000 ether, 5 ether);

        _deployHooksPerpetualAuction();
        _deployUniswapV2ArbHook();
        _configureContracts();

        // test_swapExactETHForTokens();

        vm.stopBroadcast();

        string memory initialJson = "key";
        vm.serializeAddress(initialJson, "token", address(token));
        vm.serializeAddress(initialJson, "weth", WETH);
        vm.serializeAddress(initialJson, "factory1", address(factory1));
        vm.serializeAddress(initialJson, "router1", address(router1));
        vm.serializeAddress(initialJson, "pair1", address(pair1));
        vm.serializeAddress(initialJson, "factory2", address(factory2));
        vm.serializeAddress(initialJson, "router2", address(router2));
        vm.serializeAddress(initialJson, "pair2", address(pair2));
        vm.serializeAddress(initialJson, "hooksPerpetualAuction", address(hooksPerpetualAuction));
        string memory finalJson = vm.serializeAddress(initialJson, "arbHook", address(arbHook));
        console.log(finalJson);
    }

    function test_swapExactETHForTokens() internal {
        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(token);

        router1.swapExactETHForTokens{value: 0.1 ether}(9000 ether, path, address(this), block.timestamp + 3600);
    }

    function _deployMockToken() internal {
        token = new MockERC20("Test Token", "TOKEN", 18);
        token.mint(deployer, 1_000_000_000e18);
    }

    function _deployUniswapV2Instance(uint256 tokenAmount, uint256 ethAmount)
        internal
        returns (UniswapV2Factory, UniswapV2Router, UniswapV2Pair)
    {
        UniswapV2Factory factory = new UniswapV2Factory(deployer);
        UniswapV2Router router = new UniswapV2Router(address(factory), WETH);

        UniswapV2Pair pair = UniswapV2Pair(factory.createPair(address(token), WETH));
        IWETH(WETH).deposit{value: ethAmount}();
        token.transfer(address(pair), tokenAmount);
        IWETH(WETH).transfer(address(pair), ethAmount);
        pair.mint(deployer);

        return (factory, router, pair);
    }

    function _deployHooksPerpetualAuction() internal {
        bytes32 salt = keccak256(abi.encodePacked("HooksPerpetualAuction_v1.0.0"));
        hooksPerpetualAuction = new HooksPerpetualAuction{salt: salt}();
    }

    function _deployUniswapV2ArbHook() internal {
        arbHook = new UniswapV2ArbHook();
    }

    function _configureContracts() internal {
        arbHook.setSequencer(address(hooksPerpetualAuction));
        arbHook.addDEX(address(router1), "UniswapV2-DEX1");
        arbHook.addDEX(address(router2), "UniswapV2-DEX2");
        arbHook.setAuthorizedToken(address(token), true);
        arbHook.setAuthorizedToken(WETH, true);
        arbHook.registerPair(address(token), WETH, address(pair1), address(router1));
        arbHook.registerPair(address(token), WETH, address(pair2), address(router2));
        arbHook.setMinProfitThreshold(0.001 ether);
        arbHook.setMaxTradeSize(5 ether);
        arbHook.setGasCostBuffer(0.005 ether);
        token.mint(address(arbHook), 100_000 ether);
        (bool success,) = address(arbHook).call{value: 1 ether}("");
        require(success, "Failed to send ETH to arbHook");
    }
}
