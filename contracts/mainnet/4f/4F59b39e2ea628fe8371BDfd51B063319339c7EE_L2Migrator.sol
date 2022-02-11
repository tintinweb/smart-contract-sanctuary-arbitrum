// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

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
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
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
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
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
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IArbSys} from "../../arbitrum/IArbSys.sol";

abstract contract L2ArbitrumMessenger {
    event TxToL1(
        address indexed _from,
        address indexed _to,
        uint256 indexed _id,
        bytes _data
    );

    function sendTxToL1(
        address user,
        address to,
        bytes memory data
    ) internal returns (uint256) {
        // note: this method doesn't support sending ether to L1 together with a call
        uint256 id = IArbSys(address(100)).sendTxToL1(to, data);
        emit TxToL1(user, to, id, data);
        return id;
    }

    modifier onlyL1Counterpart(address l1Counterpart) {
        require(
            msg.sender == applyL1ToL2Alias(l1Counterpart),
            "ONLY_COUNTERPART_GATEWAY"
        );
        _;
    }

    uint160 internal constant OFFSET =
        uint160(0x1111000000000000000000000000000000001111);

    // l1 addresses are transformed durng l1->l2 calls
    function applyL1ToL2Alias(address l1Address)
        internal
        pure
        returns (address l2Address)
    {
        l2Address = address(uint160(l1Address) + OFFSET);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {L2ArbitrumMessenger} from "./L2ArbitrumMessenger.sol";
import {IMigrator} from "../../interfaces/IMigrator.sol";
import "../../proxy/ManagerProxyTarget.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

interface IBondingManager {
    function bondForWithHint(
        uint256 _amount,
        address _owner,
        address _to,
        address _oldDelegateNewPosPrev,
        address _oldDelegateNewPosNext,
        address _newDelegateNewPosPrev,
        address _newDelegateNewPosNext
    ) external;
}

interface ITicketBroker {
    function fundDepositAndReserveFor(
        address _addr,
        uint256 _depositAmount,
        uint256 _reserveAmount
    ) external payable;
}

interface IMerkleSnapshot {
    function verify(
        bytes32 _id,
        bytes32[] memory _proof,
        bytes32 _leaf
    ) external view returns (bool);
}

interface IDelegatorPool {
    function initialize(address _bondingManager) external;

    function claim(address _addr, uint256 _stake) external;
}

interface ApproveLike {
    function approve(address _addr, uint256 _amount) external;
}

contract L2Migrator is ManagerProxyTarget, L2ArbitrumMessenger, IMigrator {
    address public bondingManagerAddr;
    address public ticketBrokerAddr;
    address public merkleSnapshotAddr;
    address public tokenAddr;

    address public l1MigratorAddr;
    address public delegatorPoolImpl;
    bool public claimStakeEnabled;

    mapping(address => bool) public migratedDelegators;
    mapping(address => address) public delegatorPools;
    mapping(address => uint256) public claimedDelegatedStake;
    mapping(address => mapping(uint256 => bool)) public migratedUnbondingLocks;
    mapping(address => bool) public migratedSenders;

    event L1MigratorUpdate(address _l1MigratorAddr);

    event ControllerContractUpdate(bytes32 id, address addr);

    event MigrateDelegatorFinalized(MigrateDelegatorParams params);

    event MigrateUnbondingLocksFinalized(MigrateUnbondingLocksParams params);

    event MigrateSenderFinalized(MigrateSenderParams params);

    event DelegatorPoolImplUpdate(address _delegatorPoolImpl);

    event DelegatorPoolCreated(address indexed l1Addr, address delegatorPool);

    event ClaimStakeEnabled(bool _enabled);

    event StakeClaimed(
        address indexed delegator,
        address delegate,
        uint256 stake,
        uint256 fees
    );

    /**
     * @notice L2Migrator constructor. Only invokes constructor of base Manager contract with provided Controller address
     * @dev This constructor will not initialize any state variables besides `controller`.
     * - initialize() function must be called on a proxy that uses this implementation contract immediately after deployment
     * @param _controller Address of Controller that this contract will be registered with
     */
    constructor(address _controller) Manager(_controller) {}

    function initialize(address _l1MigratorAddr, address _delegatorPoolImpl)
        external
        onlyControllerOwner
    {
        l1MigratorAddr = _l1MigratorAddr;
        delegatorPoolImpl = _delegatorPoolImpl;

        syncControllerContracts();
    }

    /**
     * @notice Sets L1Migrator
     * @param _l1MigratorAddr L1Migrator address
     */
    function setL1Migrator(address _l1MigratorAddr)
        external
        onlyControllerOwner
    {
        l1MigratorAddr = _l1MigratorAddr;
        emit L1MigratorUpdate(_l1MigratorAddr);
    }

    /**
     * @notice Sets DelegatorPool implementation contract
     * @param _delegatorPoolImpl DelegatorPool implementation contract
     */
    function setDelegatorPoolImpl(address _delegatorPoolImpl)
        external
        onlyControllerOwner
    {
        delegatorPoolImpl = _delegatorPoolImpl;
        emit DelegatorPoolImplUpdate(_delegatorPoolImpl);
    }

    /**
     * @notice Enable/disable claimStake()
     * @param _enabled True/false indicating claimStake() enabled/disabled
     */
    function setClaimStakeEnabled(bool _enabled) external onlyControllerOwner {
        claimStakeEnabled = _enabled;
        emit ClaimStakeEnabled(_enabled);
    }

    /**
     * @notice Called by L1Migrator to complete transcoder/delegator state migration
     * @param _params L1 state relevant for migration
     */
    function finalizeMigrateDelegator(MigrateDelegatorParams calldata _params)
        external
        onlyL1Counterpart(l1MigratorAddr)
    {
        require(
            !migratedDelegators[_params.l1Addr],
            "DELEGATOR_ALREADY_MIGRATED"
        );

        migratedDelegators[_params.l1Addr] = true;

        if (_params.l1Addr == _params.delegate) {
            // l1Addr is an orchestrator on L1:
            // 1. Stake _params.stake on behalf of _params.l2Addr
            // 2. Create delegator pool
            // 3. Stake non-self delegated stake on behalf of the delegator pool
            bondFor(_params.stake, _params.l2Addr, _params.l2Addr);

            address poolAddr = Clones.clone(delegatorPoolImpl);

            delegatorPools[_params.l1Addr] = poolAddr;

            // _params.delegatedStake includes _params.stake which is the orchestrator's self-stake
            // Subtract _params.stake to get the orchestrator's non-self delegated stake
            uint256 nonSelfDelegatedStake = _params.delegatedStake -
                _params.stake;
            bondFor(
                nonSelfDelegatedStake - claimedDelegatedStake[_params.l1Addr],
                poolAddr,
                _params.l2Addr
            );

            IDelegatorPool(poolAddr).initialize(bondingManagerAddr);

            emit DelegatorPoolCreated(_params.l1Addr, poolAddr);
        } else {
            // l1Addr is a delegator on L1:
            // If a delegator pool exists for _params.delegate claim stake which
            // was already migrated by delegate on behalf of _params.l2Addr.
            // Otherwise, stake _params.stake on behalf of _params.l2Addr.
            address pool = delegatorPools[_params.delegate];

            if (pool != address(0)) {
                // Claim stake that is held by the delegator pool
                IDelegatorPool(pool).claim(_params.l2Addr, _params.stake);
            } else {
                bondFor(_params.stake, _params.l2Addr, _params.delegate);
            }
        }

        claimedDelegatedStake[_params.delegate] += _params.stake;

        // Use .call() since l2Addr could be a contract that needs more gas than
        // the stipend provided by .transfer()
        // The .call() is safe without a re-entrancy guard because this function cannot be re-entered
        // by _params.l2Addr since the function can only be called by the L1Migrator via a cross-chain retryable ticket
        if (_params.fees > 0) {
            (bool ok, ) = _params.l2Addr.call{value: _params.fees}("");
            require(ok, "FINALIZE_DELEGATOR:FAIL_FEE");
        }

        emit MigrateDelegatorFinalized(_params);
    }

    /**
     * @notice Called by L1Migrator to complete unbonding locks migration
     * @param _params L1 state relevant for migration
     */
    function finalizeMigrateUnbondingLocks(
        MigrateUnbondingLocksParams calldata _params
    ) external onlyL1Counterpart(l1MigratorAddr) {
        uint256 unbondingLockIdsLen = _params.unbondingLockIds.length;
        for (uint256 i; i < unbondingLockIdsLen; i++) {
            uint256 id = _params.unbondingLockIds[i];
            require(
                !migratedUnbondingLocks[_params.l1Addr][id],
                "UNBONDING_LOCK_ALREADY_MIGRATED"
            );
            migratedUnbondingLocks[_params.l1Addr][id] = true;
        }

        bondFor(_params.total, _params.l2Addr, _params.delegate);

        emit MigrateUnbondingLocksFinalized(_params);
    }

    /**
     * @notice Called by L1Migrator to complete sender deposit/reserve migration
     * @param _params L1 state relevant for migration
     */
    function finalizeMigrateSender(MigrateSenderParams calldata _params)
        external
        onlyL1Counterpart(l1MigratorAddr)
    {
        require(!migratedSenders[_params.l1Addr], "SENDER_ALREADY_MIGRATED");

        migratedSenders[_params.l1Addr] = true;

        // msg.value for this call must be equal to deposit + reserve amounts
        ITicketBroker(ticketBrokerAddr).fundDepositAndReserveFor{
            value: _params.deposit + _params.reserve
        }(_params.l2Addr, _params.deposit, _params.reserve);

        emit MigrateSenderFinalized(_params);
    }

    receive() external payable {}

    /**
     * @notice Completes delegator migration using a Merkle proof that a delegator's state was included in a state
     * snapshot represented by a Merkle tree root
     * @dev Assume that only EOAs are included in the snapshot
     * Regardless of the caller of this function, the EOA from L1 will be able to access its stake on L2
     * @param _delegate Address that is migrating
     * @param _stake Stake of delegator on L1
     * @param _fees Fees of delegator on L1
     * @param _proof Merkle proof of inclusion in Merkle tree state snapshot
     * @param _newDelegate Optional address of a new delegate on L2
     */
    function claimStake(
        address _delegate,
        uint256 _stake,
        uint256 _fees,
        bytes32[] calldata _proof,
        address _newDelegate
    ) external {
        require(claimStakeEnabled, "CLAIM_STAKE_DISABLED");

        address delegator = msg.sender;

        require(!migratedDelegators[delegator], "CLAIM_STAKE:ALREADY_MIGRATED");

        IMerkleSnapshot merkleSnapshot = IMerkleSnapshot(merkleSnapshotAddr);

        bytes32 leaf = keccak256(
            abi.encodePacked(delegator, _delegate, _stake, _fees)
        );

        require(
            merkleSnapshot.verify(keccak256("LIP-73"), _proof, leaf),
            "CLAIM_STAKE:INVALID_PROOF"
        );

        migratedDelegators[delegator] = true;

        if (_delegate != address(0)) {
            claimedDelegatedStake[_delegate] += _stake;

            address pool = delegatorPools[_delegate];

            address delegate = _delegate;
            if (_newDelegate != address(0)) {
                delegate = _newDelegate;
            }

            if (pool != address(0)) {
                // Claim stake that is held by the delegator pool
                IDelegatorPool(pool).claim(delegator, _stake);
            } else {
                bondFor(_stake, delegator, delegate);
            }
        }

        // Only EOAs are included in the snapshot so we do not need to worry about
        // the insufficeint gas stipend with transfer()
        if (_fees > 0) {
            payable(delegator).transfer(_fees);
        }

        emit StakeClaimed(delegator, _delegate, _stake, _fees);
    }

    function bondFor(
        uint256 _amount,
        address _owner,
        address _to
    ) private {
        IBondingManager bondingManager = IBondingManager(bondingManagerAddr);

        ApproveLike(tokenAddr).approve(address(bondingManager), _amount);
        bondingManager.bondForWithHint(
            _amount,
            _owner,
            _to,
            address(0),
            address(0),
            address(0),
            address(0)
        );
    }

    /**
     * @notice Fetches addresses and sets bondingManagerAddr, ticketBrokerAddr, merkleSnapshotAddr
     * if they are different from the stored addresses
     */
    function syncControllerContracts() public {
        // Check and update BondingManager address
        bytes32 bondingManagerId = keccak256("BondingManager");
        address _bondingManagerAddr = controller.getContract(bondingManagerId);

        if (_bondingManagerAddr != bondingManagerAddr) {
            bondingManagerAddr = _bondingManagerAddr;
            emit ControllerContractUpdate(
                bondingManagerId,
                _bondingManagerAddr
            );
        }

        // Check and update TicketBroker address
        bytes32 ticketBrokerId = keccak256("TicketBroker");
        address _ticketBrokerAddr = controller.getContract(ticketBrokerId);

        if (_ticketBrokerAddr != ticketBrokerAddr) {
            ticketBrokerAddr = _ticketBrokerAddr;
            emit ControllerContractUpdate(ticketBrokerId, _ticketBrokerAddr);
        }

        // Check and update MerkleSnapshot address
        bytes32 merkleSnapshotId = keccak256("MerkleSnapshot");
        address _merkleSnapshotAddr = controller.getContract(merkleSnapshotId);

        if (_merkleSnapshotAddr != merkleSnapshotAddr) {
            merkleSnapshotAddr = _merkleSnapshotAddr;
            emit ControllerContractUpdate(
                merkleSnapshotId,
                _merkleSnapshotAddr
            );
        }

        // Check and update LivepeerToken address
        bytes32 tokenId = keccak256("LivepeerToken");
        address _tokenAddr = controller.getContract(tokenId);

        if (_tokenAddr != tokenAddr) {
            tokenAddr = _tokenAddr;
            emit ControllerContractUpdate(tokenId, _tokenAddr);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.8.9;

/**
 * @title Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality.
 */
interface IArbSys {
    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external pure returns (uint256);

    function arbChainID() external view returns (uint256);

    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty calldataForL1.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination)
        external
        payable
        returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @param destination recipient address on L1
     * @param calldataForL1 (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata calldataForL1)
        external
        payable
        returns (uint256);

    /**
     * @notice get the number of transactions issued by the given external account or the account sequence number of the given contract
     * @param account target account
     * @return the number of transactions issued by the given external account or the account sequence number of the given contract
     */
    function getTransactionCount(address account)
        external
        view
        returns (uint256);

    /**
     * @notice get the value of target L2 storage slot
     * This function is only callable from address 0 to prevent contracts from being able to call it
     * @param account target account
     * @param index target index of storage slot
     * @return stotage value for the given account at the given index
     */
    function getStorageAt(address account, uint256 index)
        external
        view
        returns (uint256);

    /**
     * @notice check if current call is coming from l1
     * @return true if the caller of this was called directly from L1
     */
    function isTopLevelCall() external view returns (bool);

    event EthWithdrawal(address indexed destAddr, uint256 amount);

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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IMigrator {
    struct MigrateDelegatorParams {
        // Address that is migrating from L1
        address l1Addr;
        // Address to use on L2
        // If null, l1Addr is used on L2
        address l2Addr;
        // Stake of l1Addr on L1
        uint256 stake;
        // Delegated stake of l1Addr on L1
        uint256 delegatedStake;
        // Fees of l1Addr on L1
        uint256 fees;
        // Delegate of l1Addr on L1
        address delegate;
    }

    struct MigrateUnbondingLocksParams {
        // Address that is migrating from L1
        address l1Addr;
        // Address to use on L2
        // If null, l1Addr is used on L2
        address l2Addr;
        // Total tokens in unbonding locks
        uint256 total;
        // IDs of unbonding locks being migrated
        uint256[] unbondingLockIds;
        // Delegate of l1Addr on L1
        address delegate;
    }

    struct MigrateSenderParams {
        // Address that is migrating from L1
        address l1Addr;
        // Address to use on L2
        // If null, l1Addr is used on L2
        address l2Addr;
        // Deposit of l1Addr on L1
        uint256 deposit;
        // Reserve of l1Addr on L1
        uint256 reserve;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IController {
    function owner() external view returns (address);

    function paused() external view returns (bool);

    function getContract(bytes32 _id) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IManager {
    event SetController(address controller);

    function setController(address _controller) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IManager} from "./IManager.sol";
import {IController} from "./IController.sol";

// Copy of https://github.com/livepeer/protocol/blob/confluence/contracts/Manager.sol
// Tests at https://github.com/livepeer/protocol/blob/confluence/test/unit/ManagerProxy.js
contract Manager is IManager {
    // Controller that contract is registered with
    IController public controller;

    // Check if sender is controller
    modifier onlyController() {
        _onlyController();
        _;
    }

    // Check if sender is controller owner
    modifier onlyControllerOwner() {
        _onlyControllerOwner();
        _;
    }

    // Check if controller is not paused
    modifier whenSystemNotPaused() {
        _whenSystemNotPaused();
        _;
    }

    // Check if controller is paused
    modifier whenSystemPaused() {
        _whenSystemPaused();
        _;
    }

    constructor(address _controller) {
        controller = IController(_controller);
    }

    /**
     * @notice Set controller. Only callable by current controller
     * @param _controller Controller contract address
     */
    function setController(address _controller) external onlyController {
        controller = IController(_controller);

        emit SetController(_controller);
    }

    function _onlyController() private view {
        require(msg.sender == address(controller), "caller must be Controller");
    }

    function _onlyControllerOwner() private view {
        require(
            msg.sender == controller.owner(),
            "caller must be Controller owner"
        );
    }

    function _whenSystemNotPaused() private view {
        require(!controller.paused(), "system is paused");
    }

    function _whenSystemPaused() private view {
        require(controller.paused(), "system is not paused");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Manager.sol";

/**
 * @title ManagerProxyTarget
 * @notice The base contract that target contracts used by a proxy contract should inherit from
 * @dev Both the target contract and the proxy contract (implemented as ManagerProxy) MUST inherit from ManagerProxyTarget in order to guarantee
 that both contracts have the same storage layout. Differing storage layouts in a proxy contract and target contract can
 potentially break the delegate proxy upgradeability mechanism
 */
abstract contract ManagerProxyTarget is Manager {
    // Used to look up target contract address in controller's registry
    bytes32 public targetContractId;
}