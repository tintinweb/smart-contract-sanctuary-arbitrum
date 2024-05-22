// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;

import { Constants } from "./libraries/Constants.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IGovernanceFeeHandler } from "./interfaces/IGovernanceFeeHandler.sol";

/// @title  GovernanceFeeHandler
/// @notice GovernanceFeeHandler contains methods for managing governance fee parameters in strategies
contract GovernanceFeeHandler is IGovernanceFeeHandler, Ownable {
    /// @dev The protocol fee value in percentage for public strategy,  decimal value <1
    ProtocolFeeRegistry private _publicStrategyFeeRegistry;
    /// @dev The protocol fee value in percentage for private strategy, decimal value <1
    ProtocolFeeRegistry private _privateStrategyFeeRegistry;

    constructor(
        ProtocolFeeRegistry memory publicStrategyFeeRegistry_,
        ProtocolFeeRegistry memory privateStrategyFeeRegistry_
    )
        Ownable()
    {
        _publicStrategyFeeRegistry = publicStrategyFeeRegistry_;
        _privateStrategyFeeRegistry = privateStrategyFeeRegistry_;
    }

    /// @inheritdoc IGovernanceFeeHandler
    function setPublicFeeRegistry(ProtocolFeeRegistry calldata newPublicStrategyFeeRegistry)
        external
        override
        onlyOwner
    {
        _checkLimit(newPublicStrategyFeeRegistry);

        _publicStrategyFeeRegistry = newPublicStrategyFeeRegistry;

        emit PublicFeeRegistryUpdated(newPublicStrategyFeeRegistry);
    }

    /// @inheritdoc IGovernanceFeeHandler
    function setPrivateFeeRegistry(ProtocolFeeRegistry calldata newPrivateStrategyFeeRegistry)
        external
        override
        onlyOwner
    {
        _checkLimit(newPrivateStrategyFeeRegistry);

        _privateStrategyFeeRegistry = newPrivateStrategyFeeRegistry;

        emit PrivateFeeRegistryUpdated(newPrivateStrategyFeeRegistry);
    }

    /// @inheritdoc IGovernanceFeeHandler
    function getGovernanceFee(bool isPrivate)
        external
        view
        override
        returns (
            uint256 lpAutomationFee,
            uint256 strategyCreationFee,
            uint256 protcolFeeOnManagement,
            uint256 protcolFeeOnPerformance
        )
    {
        if (isPrivate) {
            (lpAutomationFee, strategyCreationFee, protcolFeeOnManagement, protcolFeeOnPerformance) = (
                _privateStrategyFeeRegistry.lpAutomationFee,
                _privateStrategyFeeRegistry.strategyCreationFee,
                _privateStrategyFeeRegistry.protcolFeeOnManagement,
                _privateStrategyFeeRegistry.protcolFeeOnPerformance
            );
        } else {
            (lpAutomationFee, strategyCreationFee, protcolFeeOnManagement, protcolFeeOnPerformance) = (
                _publicStrategyFeeRegistry.lpAutomationFee,
                _publicStrategyFeeRegistry.strategyCreationFee,
                _publicStrategyFeeRegistry.protcolFeeOnManagement,
                _publicStrategyFeeRegistry.protcolFeeOnPerformance
            );
        }
    }

    /// @dev Common checks for valid fee inputs.
    function _checkLimit(ProtocolFeeRegistry calldata feeParams) private pure {
        require(feeParams.lpAutomationFee <= Constants.MAX_AUTOMATION_FEE, "LPAutomationFeeLimitExceed");
        require(feeParams.strategyCreationFee <= Constants.MAX_STRATEGY_CREATION_FEE, "StrategyFeeLimitExceed");
        require(feeParams.protcolFeeOnManagement <= Constants.MAX_PROTCOL_MANAGEMENT_FEE, "ManagementFeeLimitExceed");
        require(feeParams.protcolFeeOnPerformance <= Constants.MAX_PROTCOL_PERFORMANCE_FEE, "PerformanceFeeLimitExceed");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

library Constants {
    uint256 public constant WAD = 1e18;

    uint256 public constant MIN_INITIAL_SHARES = 1e3;

    uint256 public constant MAX_MANAGEMENT_FEE = 2e17;

    uint256 public constant MAX_PERFORMANCE_FEE = 2e17;

    uint256 public constant MAX_PROTCOL_MANAGEMENT_FEE = 2e17;

    uint256 public constant MAX_PROTCOL_PERFORMANCE_FEE = 2e17;

    uint256 public constant MAX_AUTOMATION_FEE = 2e17;

    uint256 public constant MAX_STRATEGY_CREATION_FEE = 5e17;

    uint128 public constant MAX_UINT128 = type(uint128).max;

    // keccak256("MODE")
    bytes32 public constant MODE = 0x25d202ee31c346b8c1099dc1a469d77ca5ac14ed43336c881902290b83e0a13a;

    // keccak256("EXIT_STRATEGY")
    bytes32 public constant EXIT_STRATEGY = 0xf36a697ed62dd2d982c1910275ee6172360bf72c4dc9f3b10f2d9c700666e227;

    // keccak256("REBASE_STRATEGY")
    bytes32 public constant REBASE_STRATEGY = 0x5eea0aea3d82798e316d046946dbce75c9d5995b956b9e60624a080c7f56f204;

    // keccak256("LIQUIDITY_DISTRIBUTION")
    bytes32 public constant LIQUIDITY_DISTRIBUTION = 0xeabe6f62bd74d002b0267a6aaacb5212bb162f4f87ee1c4a80ac0d2698f8a505;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

interface IGovernanceFeeHandler {
    /// @param lpAutomationFee The value of fee applied for automation of strategy
    /// @param strategyCreationFee The value of fee applied for creation of new strategy
    /// @param protcolFeeOnManagement  The value of fee applied on strategiest earned fee on managment of strategy
    /// @param protcolFeeOnPerformance The value of fee applied on strategiest earned fee on performance of strategy
    struct ProtocolFeeRegistry {
        uint256 lpAutomationFee;
        uint256 strategyCreationFee;
        uint256 protcolFeeOnManagement;
        uint256 protcolFeeOnPerformance;
    }

    /// @notice Returns the protocol fee value
    /// @param isPrivate Bool value weather strategy is private or public
    function getGovernanceFee(bool isPrivate)
        external
        view
        returns (
            uint256 lpAutomationFee,
            uint256 strategyCreationFee,
            uint256 protcolFeeOnManagement,
            uint256 protcolFeeOnPerformance
        );

    /// @notice Updates the protocol fee value for public strategy
    function setPublicFeeRegistry(ProtocolFeeRegistry calldata newPublicStrategyFeeRegistry) external;

    /// @notice Updates the protocol fee value for private strategy
    function setPrivateFeeRegistry(ProtocolFeeRegistry calldata newPrivateStrategyFeeRegistry) external;

    /// @notice Emitted when the protocol fee for public strategy has been updated
    event PublicFeeRegistryUpdated(ProtocolFeeRegistry newRegistry);

    /// @notice Emitted when the protocol fee for private strategy has been updated
    event PrivateFeeRegistryUpdated(ProtocolFeeRegistry newRegistry);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}