// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title HooksPerpetualAuction
 * @author Base Protocol Team
 * @notice A perpetual auction system for managing blockchain event hooks with competitive bidding
 * @dev This contract allows users to bid for the right to have their hooks executed when specific
 *      blockchain events occur. It uses a competitive auction model where higher bidders replace
 *      lower bidders, with automatic refunds and fee distribution to event originators.
 *
 * Key Features:
 * - Competitive bidding for hook execution rights on specific contract events
 * - Automatic refund system for outbid participants
 * - Fee sharing with event originators to refund users for their share of MEV
 * - Comprehensive ETH accounting to track reserved funds vs excess revenue
 * - Owner-controlled excess ETH withdrawal for contract maintenance
 * - Gas-limited hook execution to prevent DoS attacks
 * - Deposit management system allowing hook owners to extend their auction duration
 */
contract HooksPerpetualAuction is Ownable, ReentrancyGuard {
    /**
     * @notice Represents a hook auction slot with bidder information and execution parameters
     * @dev Each unique combination of contract address and event topic has its own Hook slot
     */
    struct Hook {
        /// @notice Address of the current highest bidder who owns this hook slot
        address owner;
        /// @notice Contract address that will be called when the hook is executed
        address entrypoint;
        /// @notice Amount of ETH paid per hook execution call
        uint256 feePerCall;
        /// @notice Total ETH deposited by the owner (feePerCall * callsRemaining)
        uint256 deposit;
        /// @notice Number of hook executions remaining before deposit is depleted
        uint256 callsRemaining;
    }

    /// @notice Mapping from contract address => event topic => Hook data
    /// @dev Allows multiple hooks per contract, one per unique event signature
    mapping(address => mapping(bytes32 => Hook)) public hooks;

    /// @notice Total amount of ETH reserved for hook deposits across all active auctions
    /// @dev Used to calculate excess ETH available for withdrawal by contract owner
    uint256 public totalReservedETH;

    /// @notice Percentage of hook fees (in basis points) shared with event originators
    /// @dev Default is 2000 basis points (20%).
    uint256 public originatorShareBps = 2000; // 20%

    /// @notice Minimum number of calls that must be deposited when creating a new bid
    /// @dev Prevents spam bids and ensures meaningful participation
    uint256 public constant MIN_CALLS_DEPOSIT = 100;

    /// @notice Maximum allowed originator share percentage (10000 = 100%)
    /// @dev Prevents owner from setting invalid share percentages above 100%
    uint256 public constant MAX_ORIGINATOR_SHARE = 10000; // 100%

    /// @notice Gas limit allocated for each hook execution call
    /// @dev Prevents hooks from consuming excessive gas and causing transaction failures
    uint256 public hookGasStipend = 1000000; // Fixed gas per hook call

    event NewBid(
        address indexed contractAddr,
        bytes32 indexed topic0,
        address indexed bidder,
        address entrypoint,
        uint256 feePerCall,
        uint256 callsDeposited
    );

    event HookExecuted(
        address indexed contractAddr,
        bytes32 indexed topic0,
        address indexed owner,
        address originator,
        uint256 feePerCall,
        uint256 originatorRefund
    );

    event DepositWithdrawn(address indexed contractAddr, bytes32 indexed topic0, address indexed owner, uint256 amount);

    event ExcessETHWithdrawn(address indexed owner, uint256 amount);

    /// @notice Thrown when insufficient ETH is provided for the required deposit
    error InsufficientDeposit();

    /// @notice Thrown when a bid is not higher than the current winning bid
    error InsufficientBid();

    /// @notice Thrown when trying to deposit for fewer than minimum required calls
    error InvalidCallsAmount();

    /// @notice Thrown when trying to execute a hook that doesn't exist
    error NoAuctionExists();

    /// @notice Thrown when non-owner tries to withdraw or modify their hook
    error OnlyOwnerCanWithdraw();

    /// @notice Thrown when trying to set originator share above maximum allowed
    error InvalidOriginatorShare();

    /// @notice Thrown when trying to withdraw excess ETH but none is available
    error NoExcessETH();

    /**
     * @notice Contract constructor that sets the deployer as the owner
     * @dev Inherits from Ownable which sets msg.sender as the initial owner
     */
    constructor() Ownable(msg.sender) {}

    /**
     * @notice Allows contract to receive ETH directly for excess accumulation
     * @dev This enables the contract to receive ETH beyond hook deposits,
     *      which can then be withdrawn by the owner via withdrawExcessETH()
     */
    receive() external payable {}

    /**
     * @notice Updates the percentage of hook fees shared with transaction originators
     * @dev Only callable by contract owner. Used to incentivize hook execution
     * @param newShareBps New originator share in basis points (e.g., 2000 = 20%)
     */
    function setOriginatorShare(uint256 newShareBps) external onlyOwner {
        if (newShareBps > MAX_ORIGINATOR_SHARE) {
            revert InvalidOriginatorShare();
        }
        originatorShareBps = newShareBps;
    }

    /**
     * @notice Updates the gas limit allocated for hook execution calls
     * @dev Only callable by contract owner. Prevents hooks from consuming too much gas
     * @param newGasStipend New gas limit for hook calls
     */
    function setHookGasStipend(uint256 newGasStipend) external onlyOwner {
        hookGasStipend = newGasStipend;
    }

    /**
     * @notice Places a bid to win the right to execute hooks for a specific contract event
     * @dev Creates or replaces an existing hook auction. Higher bids automatically refund previous bidders.
     *      The bid amount must be feePerCall * callsToDeposit, with any excess ETH refunded.
     * @param contractAddr The contract address to monitor for events
     * @param topic0 The event signature (keccak256 hash) to trigger hook execution
     * @param entrypoint The contract address that will be called when the hook executes
     * @param feePerCall Amount of ETH to pay per hook execution (must be higher than current bid)
     * @param callsToDeposit Number of hook executions to fund (minimum 100)
     *
     * Requirements:
     * - callsToDeposit must be >= MIN_CALLS_DEPOSIT (100)
     * - msg.value must be >= feePerCall * callsToDeposit
     * - feePerCall must be > current winning bid (if one exists)
     *
     * Effects:
     * - Refunds previous bidder's entire deposit if outbid
     * - Updates totalReservedETH to track new deposit
     * - Refunds any excess ETH sent beyond required deposit
     *
     * Emits: NewBid event with bid details
     */
    function bid(address contractAddr, bytes32 topic0, address entrypoint, uint256 feePerCall, uint256 callsToDeposit)
        external
        payable
        nonReentrant
    {
        if (callsToDeposit < MIN_CALLS_DEPOSIT) {
            revert InvalidCallsAmount();
        }

        uint256 requiredDeposit = feePerCall * callsToDeposit;
        if (msg.value < requiredDeposit) {
            revert InsufficientDeposit();
        }

        Hook storage currentSlot = hooks[contractAddr][topic0];

        // If slot exists, new bid must be higher than current feePerCall
        if (currentSlot.owner != address(0)) {
            if (feePerCall <= currentSlot.feePerCall) {
                revert InsufficientBid();
            }

            // Refund previous owner's remaining deposit
            uint256 refundAmount = currentSlot.deposit;
            if (refundAmount > 0) {
                totalReservedETH -= refundAmount;
                payable(currentSlot.owner).transfer(refundAmount);
            }
        }

        // Create new auction slot
        hooks[contractAddr][topic0] = Hook({
            owner: msg.sender,
            entrypoint: entrypoint,
            feePerCall: feePerCall,
            deposit: requiredDeposit,
            callsRemaining: callsToDeposit
        });

        // Update reserved ETH tracking
        totalReservedETH += requiredDeposit;

        // Refund excess payment
        uint256 excess = msg.value - requiredDeposit;
        if (excess > 0) {
            payable(msg.sender).transfer(excess);
        }

        emit NewBid(contractAddr, topic0, msg.sender, entrypoint, feePerCall, callsToDeposit);
    }

    /**
     * @notice Executes a hook for a specific contract event and pays the originator
     * @dev Calls the winning bidder's entrypoint with provided event data and distributes fees.
     *      The hook execution is gas-limited to prevent DoS attacks. Fees are deducted regardless
     *      of hook execution success to prevent griefing attacks.
     * @param contractAddr The contract address that triggered the event
     * @param topic0 The event signature that was emitted
     * @param topic1 The first indexed event parameter (if any)
     * @param topic2 The second indexed event parameter (if any)
     * @param topic3 The third indexed event parameter (if any)
     * @param eventData The encoded event data to pass to the hook entrypoint
     * @param originator Address of the user who initiated the transaction causing this event
     *
     * Requirements:
     * - Hook auction must exist for the given contractAddr/topic0 combination
     * - Hook must have callsRemaining > 0
     *
     * Effects:
     * - Sends originatorShareBps percentage of feePerCall to originator
     * - Calls hook entrypoint with gas limit of hookGasStipend
     * - Deducts feePerCall from hook deposit regardless of execution success
     * - Decrements callsRemaining by 1 and deletes the hook if callsRemaining is 0
     * - Decreases totalReservedETH by feePerCall
     *
     * Emits: HookExecuted event with execution details
     */
    function executeHook(
        address contractAddr,
        bytes32 topic0,
        bytes32 topic1,
        bytes32 topic2,
        bytes32 topic3,
        bytes calldata eventData,
        address originator
    ) external nonReentrant {
        Hook storage slot = hooks[contractAddr][topic0];

        if (slot.owner == address(0)) {
            revert NoAuctionExists();
        }

        if (slot.callsRemaining == 0) {
            revert InsufficientDeposit();
        }

        uint256 originatorRefund = (slot.feePerCall * originatorShareBps) / 10000;
        uint256 netFee = slot.feePerCall - originatorRefund;

        // Send refund to event originator
        if (originatorRefund > 0 && originator != address(0)) {
            payable(originator).transfer(originatorRefund);
        }

        // Execute hook with fixed gas stipend
        (bool success,) = slot.entrypoint.call{gas: hookGasStipend}(
            abi.encodeWithSignature(
                "onHook(address,bytes32,bytes32,bytes32,bytes32,bytes)",
                contractAddr,
                topic0,
                topic1,
                topic2,
                topic3,
                eventData
            )
        );

        // Always deduct fee regardless of hook success
        slot.deposit -= slot.feePerCall;
        slot.callsRemaining--;

        if (slot.callsRemaining == 0) {
            delete hooks[contractAddr][topic0];
        }

        totalReservedETH -= slot.feePerCall;

        emit HookExecuted(contractAddr, topic0, slot.owner, originator, slot.feePerCall, originatorRefund);
    }

    /**
     * @notice Allows hook owners to withdraw their remaining deposit and forfeit the auction
     * @dev Completely removes the hook auction and refunds all remaining funds to the owner.
     *      This effectively ends the auction for this contract/topic combination.
     * @param contractAddr The contract address of the hook to withdraw
     * @param topic0 The event signature of the hook to withdraw
     *
     * Requirements:
     * - Only the current hook owner can withdraw
     * - Hook must exist (owner != address(0))
     *
     * Effects:
     * - Transfers entire remaining deposit to hook owner
     * - Deletes the hook auction slot completely
     * - Decreases totalReservedETH by the withdrawn amount
     *
     * Emits: DepositWithdrawn event with withdrawal details
     */
    function withdrawDeposit(address contractAddr, bytes32 topic0) external nonReentrant {
        Hook storage slot = hooks[contractAddr][topic0];

        if (slot.owner != msg.sender) {
            revert OnlyOwnerCanWithdraw();
        }

        uint256 withdrawAmount = slot.deposit;
        if (withdrawAmount > 0) {
            slot.deposit = 0;
            slot.callsRemaining = 0;
            totalReservedETH -= withdrawAmount;
            delete hooks[contractAddr][topic0];

            payable(msg.sender).transfer(withdrawAmount);
            emit DepositWithdrawn(contractAddr, topic0, msg.sender, withdrawAmount);
        }
    }

    /**
     * @notice Allows hook owners to extend their auction by adding more calls
     * @dev Hook owners can deposit additional ETH to extend the duration of their hook execution.
     *      The additional deposit uses the same feePerCall rate as the original bid.
     * @param contractAddr The contract address of the hook to extend
     * @param topic0 The event signature of the hook to extend
     * @param additionalCalls Number of additional hook executions to fund
     *
     * Requirements:
     * - Only the current hook owner can add deposits
     * - Hook must exist (owner != address(0))
     * - msg.value must be >= feePerCall * additionalCalls
     *
     * Effects:
     * - Increases hook deposit and callsRemaining
     * - Increases totalReservedETH by the additional deposit amount
     * - Refunds any excess ETH sent beyond required deposit
     */
    function addDeposit(address contractAddr, bytes32 topic0, uint256 additionalCalls) external payable nonReentrant {
        Hook storage slot = hooks[contractAddr][topic0];

        if (slot.owner != msg.sender) {
            revert OnlyOwnerCanWithdraw();
        }

        uint256 requiredDeposit = slot.feePerCall * additionalCalls;
        if (msg.value < requiredDeposit) {
            revert InsufficientDeposit();
        }

        slot.deposit += requiredDeposit;
        slot.callsRemaining += additionalCalls;
        totalReservedETH += requiredDeposit;

        // Refund excess
        uint256 excess = msg.value - requiredDeposit;
        if (excess > 0) {
            payable(msg.sender).transfer(excess);
        }
    }

    /**
     * @notice Allows contract owner to withdraw excess ETH beyond reserved hook deposits
     * @dev This function enables withdrawal of ETH that accumulates from hook execution fees
     *      after paying originator refunds. Only the contract owner can call this function.
     *
     * Requirements:
     * - Only contract owner can call this function
     * - Contract balance must be greater than totalReservedETH
     *
     * Effects:
     * - Transfers excess ETH (contractBalance - totalReservedETH) to owner
     * - Does not affect hook deposits or reserved ETH accounting
     *
     * Emits: ExcessETHWithdrawn event with withdrawal details
     */
    function withdrawExcessETH() external onlyOwner nonReentrant {
        uint256 contractBalance = address(this).balance;
        uint256 excessETH = contractBalance - totalReservedETH;

        if (excessETH == 0) {
            revert NoExcessETH();
        }

        payable(owner()).transfer(excessETH);
        emit ExcessETHWithdrawn(owner(), excessETH);
    }

    /**
     * @notice Returns the amount of excess ETH available for withdrawal by the owner
     * @dev Calculates the difference between contract balance and reserved ETH for hooks.
     *      This represents accumulated fees from hook executions after originator refunds.
     * @return uint256 Amount of excess ETH that can be withdrawn by the contract owner
     */
    function getExcessETH() external view returns (uint256) {
        uint256 contractBalance = address(this).balance;
        return contractBalance > totalReservedETH ? contractBalance - totalReservedETH : 0;
    }

    /**
     * @notice Retrieves complete hook information for a specific contract/event combination
     * @dev Returns the Hook struct containing all auction details including owner, entrypoint,
     *      fee structure, deposit amount, and remaining calls.
     * @param contractAddr The contract address being monitored
     * @param topic0 The event signature for the hook
     * @return Hook memory struct containing all hook auction details
     */
    function getHook(address contractAddr, bytes32 topic0) external view returns (Hook memory) {
        return hooks[contractAddr][topic0];
    }
}
