// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

import {CrossChainEnabledArbitrumL2} from
    "openzeppelin-contracts/contracts/crosschain/arbitrum/CrossChainEnabledArbitrumL2.sol";

import {VeRecipient} from "../VeRecipient.sol";

contract VeRecipientArbitrum is VeRecipient, CrossChainEnabledArbitrumL2 {
    constructor(address beacon_, address owner_) VeRecipient(beacon_, owner_) {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (crosschain/arbitrum/CrossChainEnabledArbitrumL2.sol)

pragma solidity ^0.8.4;

import "../CrossChainEnabled.sol";
import "./LibArbitrumL2.sol";

/**
 * @dev https://arbitrum.io/[Arbitrum] specialization or the
 * {CrossChainEnabled} abstraction the L2 side (arbitrum).
 *
 * This version should only be deployed on L2 to process cross-chain messages
 * originating from L1. For the other side, use {CrossChainEnabledArbitrumL1}.
 *
 * Arbitrum L2 includes the `ArbSys` contract at a fixed address. Therefore,
 * this specialization of {CrossChainEnabled} does not include a constructor.
 *
 * _Available since v4.6._
 *
 * WARNING: There is currently a bug in Arbitrum that causes this contract to
 * fail to detect cross-chain calls when deployed behind a proxy. This will be
 * fixed when the network is upgraded to Arbitrum Nitro, currently scheduled for
 * August 31st 2022.
 */
abstract contract CrossChainEnabledArbitrumL2 is CrossChainEnabled {
    /**
     * @dev see {CrossChainEnabled-_isCrossChain}
     */
    function _isCrossChain() internal view virtual override returns (bool) {
        return LibArbitrumL2.isCrossChain(LibArbitrumL2.ARBSYS);
    }

    /**
     * @dev see {CrossChainEnabled-_crossChainSender}
     */
    function _crossChainSender() internal view virtual override onlyCrossChain returns (address) {
        return LibArbitrumL2.crossChainSender(LibArbitrumL2.ARBSYS);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

import {CrossChainEnabled} from "openzeppelin-contracts/contracts/crosschain/CrossChainEnabled.sol";

import "./base/Structs.sol";
import {BoringOwnable} from "./base/BoringOwnable.sol";

/// @title VeRecipient
/// @author zefram.eth
/// @notice Recipient on non-Ethereum networks that receives data from the Ethereum beacon
/// and makes vetoken balances available on this network.
abstract contract VeRecipient is CrossChainEnabled, BoringOwnable {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error VeRecipient__InvalidInput();

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event UpdateVeBalance(address indexed user);
    event SetBeacon(address indexed newBeacon);

    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------

    uint256 internal constant MAX_ITERATIONS = 255;

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    address public beacon;
    mapping(address => Point) public userData;
    Point public globalData;
    mapping(uint256 => int128) public slopeChanges;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(address beacon_, address owner_) BoringOwnable(owner_) {
        beacon = beacon_;
        emit SetBeacon(beacon_);
    }

    /// -----------------------------------------------------------------------
    /// Crosschain functions
    /// -----------------------------------------------------------------------

    /// @notice Called by VeBeacon from Ethereum via bridge to update vetoken balance & supply info.
    function updateVeBalance(
        address user,
        int128 userBias,
        int128 userSlope,
        uint256 userTs,
        int128 globalBias,
        int128 globalSlope,
        uint256 globalTs,
        SlopeChange[] calldata slopeChanges_
    ) external onlyCrossChainSender(beacon) {
        userData[user] = Point({bias: userBias, slope: userSlope, ts: userTs});
        globalData = Point({bias: globalBias, slope: globalSlope, ts: globalTs});

        uint256 slopeChangesLength = slopeChanges_.length;
        for (uint256 i; i < slopeChangesLength;) {
            slopeChanges[slopeChanges_[i].ts] = slopeChanges_[i].change;

            unchecked {
                ++i;
            }
        }

        emit UpdateVeBalance(user);
    }

    /// -----------------------------------------------------------------------
    /// Owner functions
    /// -----------------------------------------------------------------------

    /// @notice Called by owner to update the beacon address.
    /// @dev The beacon address needs to be updateable because VeBeacon needs to be redeployed
    /// when support for a new network is added.
    /// @param newBeacon The new address
    function setBeacon(address newBeacon) external onlyOwner {
        if (newBeacon == address(0)) revert VeRecipient__InvalidInput();
        beacon = newBeacon;
        emit SetBeacon(newBeacon);
    }

    /// -----------------------------------------------------------------------
    /// View functions
    /// -----------------------------------------------------------------------

    /// @notice Computes the vetoken balance of a user. Returns 0 if the user's data hasn't
    /// been broadcasted from VeBeacon. Exhibits the same time-decay behavior as regular
    /// VotingEscrow contracts.
    /// @param user The user address to query
    /// @return The user's vetoken balance.
    function balanceOf(address user) external view returns (uint256) {
        // storage loads
        Point memory u = userData[user];

        // compute vetoken balance
        int256 veBalance = u.bias - u.slope * int128(int256(block.timestamp - u.ts));
        if (veBalance < 0) veBalance = 0;
        return uint256(veBalance);
    }

    /// @notice Computes the total supply of the vetoken. Returns 0 if data hasn't
    /// been broadcasted from VeBeacon. Exhibits the same time-decay behavior as regular
    /// VotingEscrow contracts.
    /// @dev The value may diverge from the correct value if `updateVeBalance()` hasn't been
    /// called for 8 consecutive epochs (~2 months). This is because we limit the size of each
    /// slopeChanges update to limit gas costs.
    /// @return The vetoken's total supply
    function totalSupply() external view returns (uint256) {
        Point memory g = globalData;
        uint256 ti = (g.ts / (1 weeks)) * (1 weeks);
        for (uint256 i; i < MAX_ITERATIONS;) {
            ti += 1 weeks;
            int128 slopeChange;
            if (ti > block.timestamp) {
                ti = block.timestamp;
            } else {
                slopeChange = slopeChanges[ti];
            }
            g.bias -= g.slope * int128(int256(ti - g.ts));
            if (ti == block.timestamp) break;
            g.slope += slopeChange;
            g.ts = ti;

            unchecked {
                ++i;
            }
        }

        if (g.bias < 0) g.bias = 0;
        return uint256(uint128(g.bias));
    }

    /// @notice Returns the timestamp a user's vetoken position was last updated. Returns 0 if the user's data
    /// has never been broadcasted.
    /// @dev Added for compatibility with kick() in gauge contracts.
    /// @param user The user's address
    /// @return The last update timestamp
    function user_point_history__ts(address user, uint256 /*epoch*/ ) external view returns (uint256) {
        return userData[user].ts;
    }

    /// @notice Just returns 0.
    /// @dev Added for compatibility with kick() in gauge contracts.
    function user_point_epoch(address /*user*/ ) external pure returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (crosschain/CrossChainEnabled.sol)

pragma solidity ^0.8.4;

import "./errors.sol";

/**
 * @dev Provides information for building cross-chain aware contracts. This
 * abstract contract provides accessors and modifiers to control the execution
 * flow when receiving cross-chain messages.
 *
 * Actual implementations of cross-chain aware contracts, which are based on
 * this abstraction, will  have to inherit from a bridge-specific
 * specialization. Such specializations are provided under
 * `crosschain/<chain>/CrossChainEnabled<chain>.sol`.
 *
 * _Available since v4.6._
 */
abstract contract CrossChainEnabled {
    /**
     * @dev Throws if the current function call is not the result of a
     * cross-chain execution.
     */
    modifier onlyCrossChain() {
        if (!_isCrossChain()) revert NotCrossChainCall();
        _;
    }

    /**
     * @dev Throws if the current function call is not the result of a
     * cross-chain execution initiated by `account`.
     */
    modifier onlyCrossChainSender(address expected) {
        address actual = _crossChainSender();
        if (expected != actual) revert InvalidCrossChainSender(actual, expected);
        _;
    }

    /**
     * @dev Returns whether the current function call is the result of a
     * cross-chain message.
     */
    function _isCrossChain() internal view virtual returns (bool);

    /**
     * @dev Returns the address of the sender of the cross-chain message that
     * triggered the current function call.
     *
     * IMPORTANT: Should revert with `NotCrossChainCall` if the current function
     * call is not the result of a cross-chain message.
     */
    function _crossChainSender() internal view virtual returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (crosschain/arbitrum/LibArbitrumL2.sol)

pragma solidity ^0.8.4;

import {IArbSys as ArbitrumL2_Bridge} from "../../vendor/arbitrum/IArbSys.sol";
import "../errors.sol";

/**
 * @dev Primitives for cross-chain aware contracts for
 * https://arbitrum.io/[Arbitrum].
 *
 * This version should only be used on L2 to process cross-chain messages
 * originating from L1. For the other side, use {LibArbitrumL1}.
 *
 * WARNING: There is currently a bug in Arbitrum that causes this contract to
 * fail to detect cross-chain calls when deployed behind a proxy. This will be
 * fixed when the network is upgraded to Arbitrum Nitro, currently scheduled for
 * August 31st 2022.
 */
library LibArbitrumL2 {
    /**
     * @dev Returns whether the current function call is the result of a
     * cross-chain message relayed by `arbsys`.
     */
    address public constant ARBSYS = 0x0000000000000000000000000000000000000064;

    function isCrossChain(address arbsys) internal view returns (bool) {
        return ArbitrumL2_Bridge(arbsys).wasMyCallersAddressAliased();
    }

    /**
     * @dev Returns the address of the sender that triggered the current
     * cross-chain message through `arbsys`.
     *
     * NOTE: {isCrossChain} should be checked before trying to recover the
     * sender, as it will revert with `NotCrossChainCall` if the current
     * function call is not the result of a cross-chain message.
     */
    function crossChainSender(address arbsys) internal view returns (address) {
        if (!isCrossChain(arbsys)) revert NotCrossChainCall();

        return ArbitrumL2_Bridge(arbsys).myCallersAddressWithoutAliasing();
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

struct SlopeChange {
    uint256 ts;
    int128 change;
}

struct Point {
    int128 bias;
    int128 slope;
    uint256 ts;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Simplified by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    error BoringOwnable__ZeroAddress();
    error BoringOwnable__NotPendingOwner();
    error BoringOwnable__NotOwner();

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address owner_) {
        owner = owner_;
        emit OwnershipTransferred(address(0), owner_);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(address newOwner, bool direct, bool renounce) public onlyOwner {
        if (direct) {
            // Checks
            if (newOwner == address(0) && !renounce) revert BoringOwnable__ZeroAddress();

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        if (msg.sender != _pendingOwner) revert BoringOwnable__NotPendingOwner();

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        if (msg.sender != owner) revert BoringOwnable__NotOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (crosschain/errors.sol)

pragma solidity ^0.8.4;

error NotCrossChainCall();
error InvalidCrossChainSender(address actual, address expected);

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1
// OpenZeppelin Contracts (last updated v4.8.0) (vendor/arbitrum/IArbSys.sol)

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */
interface IArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
     * @return block hash
     */
    function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);

    /**
     * @notice Gets the rollup's unique chain identifier
     * @return Chain identifier as int
     */
    function arbChainID() external view returns (uint256);

    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external view returns (uint256);

    /**
     * @notice Returns 0 since Nitro has no concept of storage gas
     * @return uint 0
     */
    function getStorageGasAvailable() external view returns (uint256);

    /**
     * @notice (deprecated) check if current call is top level (meaning it was triggered by an EoA or a L1 contract)
     * @dev this call has been deprecated and may be removed in a future release
     * @return true if current execution frame is not a call by another L2 contract
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param unused argument no longer used
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address unused) external pure returns (address);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty data.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination) external payable returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
     * to a contract address without any code (as enforced by the Bridge contract).
     * @param destination recipient address on L1
     * @param data (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata data) external payable returns (uint256);

    /**
     * @notice Get send Merkle tree state
     * @return size number of sends in the history
     * @return root root hash of the send history
     * @return partials hashes of partial subtrees in the send history tree
     */
    function sendMerkleTreeState() external view returns (uint256 size, bytes32 root, bytes32[] memory partials);

    /**
     * @notice creates a send txn from L2 to L1
     * @param position = (level << 192) + leaf = (0 << 192) + leaf = leaf
     */
    event L2ToL1Tx(
        address caller,
        address indexed destination,
        uint256 indexed hash,
        uint256 indexed position,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /// @dev DEPRECATED in favour of the new L2ToL1Tx event above after the nitro upgrade
    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /**
     * @notice logs a merkle branch for proof synthesis
     * @param reserved an index meant only to align the 4th index with L2ToL1Transaction's 4th event
     * @param hash the merkle hash
     * @param position = (level << 192) + leaf
     */
    event SendMerkleUpdate(uint256 indexed reserved, bytes32 indexed hash, uint256 indexed position);
}