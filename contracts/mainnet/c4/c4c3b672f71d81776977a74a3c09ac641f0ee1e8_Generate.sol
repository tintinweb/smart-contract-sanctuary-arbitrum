// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Errors} from "src/libraries/Errors.sol";
import {IVault} from "src/interfaces/IVault.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IOperator} from "src/storage/interfaces/IOperator.sol";

library Generate {
    /// @notice deploys a new clone of `StvAccount`
    /// @param capacityOfStv capacity of the stv
    /// @param manager address of the manager
    /// @param operator address of the operator
    /// @param maxFundraisingPeriod max fundraising period for an stv
    function generate(uint96 capacityOfStv, address manager, address operator, uint40 maxFundraisingPeriod)
        external
        returns (IVault.StvInfo memory stv)
    {
        address stvAccountImplementation = IOperator(operator).getAddress("STVACCOUNT");
        address defaultStableCoin = IOperator(operator).getAddress("DEFAULTSTABLECOIN");

        if (capacityOfStv < 1e6) revert Errors.InputMismatch();

        stv.manager = manager;
        stv.endTime = uint40(block.timestamp) + maxFundraisingPeriod;
        stv.capacityOfStv = capacityOfStv;

        bytes32 salt = keccak256(
            abi.encodePacked(
                manager, defaultStableCoin, capacityOfStv, maxFundraisingPeriod, block.timestamp, block.chainid
            )
        );
        address contractAddress = Clones.cloneDeterministic(stvAccountImplementation, salt);
        stv.stvId = contractAddress;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

library Errors {
    // Zero Errors
    error ZeroAmount();
    error ZeroAddress();
    error ZeroTotalRaised();
    error ZeroClaimableAmount();

    // Modifier Errors
    error NotOwner();
    error NotAdmin();
    error CallerNotVault();
    error CallerNotTrade();
    error CallerNotVaultOwner();
    error CallerNotGenerate();
    error NoAccess();
    error NotPlugin();

    // State Errors
    error BelowMinFundraisingPeriod();
    error AboveMaxFundraisingPeriod();
    error BelowMinLeverage();
    error AboveMaxLeverage();
    error BelowMinEndTime();
    error TradeTokenNotApplicable();

    // STV errors
    error StvDoesNotExist();
    error AlreadyOpened();
    error MoreThanTotalRaised();
    error MoreThanTotalReceived();
    error StvNotOpen();
    error StvNotClose();
    error ClaimNotApplicable();
    error StvStatusMismatch();

    // General Errors
    error BalanceLessThanAmount();
    error FundraisingPeriodEnded();
    error TotalRaisedMoreThanCapacity();
    error StillFundraising();
    error CommandMisMatch();
    error TradeCommandMisMatch();
    error NotInitialised();
    error Initialised();
    error LengthMismatch();
    error TransferFailed();
    error DelegateCallFailed();
    error CallFailed(bytes);
    error AccountAlreadyExists();
    error SwapFailed();
    error ExchangeDataMismatch();
    error AccountNotExists();
    error InputMismatch();
    error AboveMaxDistributeIndex();
    error BelowMinStvDepositAmount();

    // Protocol specific errors
    error GmxFeesMisMatch();
    error UpdateOrderRequestMisMatch();
    error CancelOrderRequestMisMatch();
    error WrongRewardClaimToken();

    // Subscriptions
    error NotASubscriber();
    error AlreadySubscribed();
    error MoreThanLimit();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IVault {
    /// @notice Enum to describe the trading status of the vault
    /// @dev NOT_OPENED - Not open
    /// @dev OPEN - opened position
    /// @dev CANCELLED_WITH_ZERO_RAISE - cancelled without any raise
    /// @dev CANCELLED_WITH_NO_FILL - cancelled with raise but not opening a position
    /// @dev CANCELLED_BY_MANAGER - cancelled by the manager after raising
    /// @dev DISTRIBUTED - distributed fees
    /// @dev LIQUIDATED - liquidated position
    enum StvStatus {
        NOT_OPENED,
        OPEN,
        CANCELLED_WITH_ZERO_RAISE,
        CANCELLED_WITH_NO_FILL,
        CANCELLED_BY_MANAGER,
        DISTRIBUTED,
        LIQUIDATED
    }

    struct StvInfo {
        address stvId;
        uint40 endTime;
        StvStatus status;
        address manager;
        uint96 capacityOfStv;
    }

    struct StvBalance {
        uint96 totalRaised;
        uint96 totalRemainingAfterDistribute;
    }

    struct InvestorInfo {
        uint96 depositAmount;
        uint96 claimedAmount;
        bool claimed;
    }

    function getQ() external view returns (address);
    function maxFundraisingPeriod() external view returns (uint40);
    function distributeOut(address stvId, bool isCancel, uint256 indexFrom, uint256 indexTo) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IOperator {
    function getMaxDistributeIndex() external view returns (uint256);
    function getAddress(string calldata adapter) external view returns (address);
    function getAddresses(string[] calldata adapters) external view returns (address[] memory);
    function getTraderAccount(address trader) external view returns (address);
    function getPlugin(address plugin) external view returns (bool);
    function getPlugins(address[] calldata plugins) external view returns (bool[] memory);
    function setAddress(string calldata adapter, address addr) external;
    function setAddresses(string[] calldata adapters, address[] calldata addresses) external;
    function setPlugin(address plugin, bool isPlugin) external;
    function setPlugins(address[] calldata plugins, bool[] calldata isPlugin) external;
    function setTraderAccount(address trader, address account) external;
    function getAllSubscribers(address manager) external view returns (address[] memory);
    function getIsSubscriber(address manager, address subscriber) external view returns (bool);
    function getSubscriptionAmount(address manager, address subscriber) external view returns (uint96);
    function getTotalSubscribedAmountPerManager(address manager) external view returns (uint96);
    function setSubscribe(address manager, address subscriber, uint96 maxLimit) external;
    function setUnsubscribe(address manager, address subscriber) external;
}