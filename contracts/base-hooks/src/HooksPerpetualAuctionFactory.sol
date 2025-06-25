// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./HooksPerpetualAuction.sol";

/**
 * @title HooksPerpetualAuctionFactory
 * @notice Factory contract for deploying HooksPerpetualAuction contracts to deterministic addresses
 */
contract HooksPerpetualAuctionFactory {
    event HooksAuctionDeployed(
        address indexed auction,
        address indexed deployer,
        bytes32 salt,
        string version
    );
    
    mapping(bytes32 => address) public deployedAuctions;
    
    /**
     * @notice Deploy a HooksPerpetualAuction contract to a deterministic address
     * @param salt The salt to use for CREATE2 deployment
     * @param version Version string for tracking
     * @return auction The address of the deployed contract
     */
    function deployAuction(bytes32 salt, string memory version) 
        external 
        returns (address auction) 
    {
        require(deployedAuctions[salt] == address(0), "Already deployed with this salt");
        
        // Deploy using CREATE2
        auction = address(new HooksPerpetualAuction{salt: salt}());
        
        deployedAuctions[salt] = auction;
        
        emit HooksAuctionDeployed(auction, msg.sender, salt, version);
        
        return auction;
    }
    
    /**
     * @notice Compute the address where a contract would be deployed
     * @param salt The salt to use for CREATE2
     * @return The computed address
     */
    function computeAddress(bytes32 salt) external view returns (address) {
        bytes memory bytecode = abi.encodePacked(
            type(HooksPerpetualAuction).creationCode
        );
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );
        return address(uint160(uint256(hash)));
    }
    
    /**
     * @notice Generate a salt based on deployer and version
     * @param deployer The deployer address
     * @param version Version string
     * @return Generated salt
     */
    function generateSalt(address deployer, string memory version) 
        external 
        pure 
        returns (bytes32) 
    {
        return keccak256(abi.encodePacked(deployer, version));
    }
}