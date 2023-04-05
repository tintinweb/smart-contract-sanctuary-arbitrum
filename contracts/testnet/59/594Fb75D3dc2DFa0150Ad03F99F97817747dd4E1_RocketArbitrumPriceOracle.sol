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

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

/**
 * @notice DEPRECATED - only for classic version, see new repo (https://github.com/OffchainLabs/nitro/tree/master/contracts)
 * for new updates
 */
interface IBridge {
    event MessageDelivered(
        uint256 indexed messageIndex,
        bytes32 indexed beforeInboxAcc,
        address inbox,
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    );

    event BridgeCallTriggered(
        address indexed outbox,
        address indexed destAddr,
        uint256 amount,
        bytes data
    );

    event InboxToggle(address indexed inbox, bool enabled);

    event OutboxToggle(address indexed outbox, bool enabled);

    function deliverMessageToInbox(
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    ) external payable returns (uint256);

    function executeCall(
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (bool success, bytes memory returnData);

    // These are only callable by the admin
    function setInbox(address inbox, bool enabled) external;

    function setOutbox(address inbox, bool enabled) external;

    // View functions

    function activeOutbox() external view returns (address);

    function allowedInboxes(address inbox) external view returns (bool);

    function allowedOutboxes(address outbox) external view returns (bool);

    function inboxAccs(uint256 index) external view returns (bytes32);

    function messageCount() external view returns (uint256);

    function isNitroReady() external view returns (uint256);
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

import "./IBridge.sol";
import "./IMessageProvider.sol";

/**
 * @notice DEPRECATED - only for classic version, see new repo (https://github.com/OffchainLabs/nitro/tree/master/contracts)
 * for new updates
 */
interface IInbox is IMessageProvider {
    function sendL2Message(bytes calldata messageData) external returns (uint256);

    function sendUnsignedTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 nonce,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256);

    function sendContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256);

    function sendL1FundedUnsignedTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 nonce,
        address destAddr,
        bytes calldata data
    ) external payable returns (uint256);

    function sendL1FundedContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        bytes calldata data
    ) external payable returns (uint256);

    function createRetryableTicket(
        address destAddr,
        uint256 arbTxCallValue,
        uint256 maxSubmissionCost,
        address submissionRefundAddress,
        address valueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable returns (uint256);

    function unsafeCreateRetryableTicket(
        address destAddr,
        uint256 arbTxCallValue,
        uint256 maxSubmissionCost,
        address submissionRefundAddress,
        address valueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable returns (uint256);

    function depositEth(uint256 maxSubmissionCost) external payable returns (uint256);

    function bridge() external view returns (IBridge);

    function pauseCreateRetryables() external;

    function unpauseCreateRetryables() external;

    function startRewriteAddress() external;

    function stopRewriteAddress() external;
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

/**
 * @notice DEPRECATED - only for classic version, see new repo (https://github.com/OffchainLabs/nitro/tree/master/contracts)
 * for new updates
 */
interface IMessageProvider {
    event InboxMessageDelivered(uint256 indexed messageNum, bytes data);

    event InboxMessageDeliveredFromOrigin(uint256 indexed messageNum);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library AddressAliasHelper {
    uint160 internal constant OFFSET = uint160(0x1111000000000000000000000000000000001111);

    /// @notice Utility function that converts the address in the L1 that submitted a tx to
    /// the inbox to the msg.sender viewed in the L2
    /// @param l1Address the address in the L1 that triggered the tx to L2
    /// @return l2Address L2 address as viewed in msg.sender
    function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
        unchecked {
            l2Address = address(uint160(l1Address) + OFFSET);
        }
    }

    /// @notice Utility function that converts the msg.sender viewed in the L2 to the
    /// address in the L1 that submitted a tx to the inbox
    /// @param l2Address L2 address as viewed in msg.sender
    /// @return l1Address the address in the L1 that triggered the tx to L2
    function undoL1ToL2Alias(address l2Address) internal pure returns (address l1Address) {
        unchecked {
            l1Address = address(uint160(l2Address) - OFFSET);
        }
    }
}

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketStorageInterface {

    // Deploy status
    function getDeployedStatus() external view returns (bool);

    // Guardian
    function getGuardian() external view returns(address);
    function setGuardian(address _newAddress) external;
    function confirmGuardian() external;

    // Getters
    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getString(bytes32 _key) external view returns (string memory);
    function getBytes(bytes32 _key) external view returns (bytes memory);
    function getBool(bytes32 _key) external view returns (bool);
    function getInt(bytes32 _key) external view returns (int);
    function getBytes32(bytes32 _key) external view returns (bytes32);

    // Setters
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string calldata _value) external;
    function setBytes(bytes32 _key, bytes calldata _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
    function setBytes32(bytes32 _key, bytes32 _value) external;

    // Deleters
    function deleteAddress(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;
    function deleteBytes32(bytes32 _key) external;

    // Arithmetic
    function addUint(bytes32 _key, uint256 _amount) external;
    function subUint(bytes32 _key, uint256 _amount) external;

    // Protected storage
    function getNodeWithdrawalAddress(address _nodeAddress) external view returns (address);
    function getNodePendingWithdrawalAddress(address _nodeAddress) external view returns (address);
    function setWithdrawalAddress(address _nodeAddress, address _newWithdrawalAddress, bool _confirm) external;
    function confirmWithdrawalAddress(address _nodeAddress) external;
}

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketNetworkBalancesInterface {
    function getBalancesBlock() external view returns (uint256);
    function getLatestReportableBlock() external view returns (uint256);
    function getTotalETHBalance() external view returns (uint256);
    function getStakingETHBalance() external view returns (uint256);
    function getTotalRETHSupply() external view returns (uint256);
    function getETHUtilizationRate() external view returns (uint256);
    function submitBalances(uint256 _block, uint256 _total, uint256 _staking, uint256 _rethSupply) external;
    function executeUpdateBalances(uint256 _block, uint256 _totalEth, uint256 _stakingEth, uint256 _rethSupply) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "@arb-bridge-eth/contracts/bridge/interfaces/IInbox.sol";

import "rocketpool/contracts/interface/network/RocketNetworkBalancesInterface.sol";
import "rocketpool/contracts/interface/RocketStorageInterface.sol";

/// @author Kane Wallmann (Rocket Pool)
/// @notice Retrieves the rETH exchange rate from Rocket Pool and submits it to the oracle contract on Polygon
contract RocketArbitrumPriceMessenger {
    // Immutables
    RocketStorageInterface immutable rocketStorage;
    bytes32 immutable rocketNetworkBalancesKey;
    IInbox immutable public inbox;

    /// @notice The most recently submitted rate
    uint256 lastRate;

    /// @notice Target address of the oracle contract on L2
    address public l2Target;

    constructor(RocketStorageInterface _rocketStorage, address _inbox) {
        rocketStorage = _rocketStorage;
        inbox = IInbox(_inbox);
        // Precompute storage key for RocketNetworkBalances address
        rocketNetworkBalancesKey = keccak256(abi.encodePacked("contract.address", "rocketNetworkBalances"));
    }

    /// @notice Sets the L2 oracle contract address
    function updateL2Target(address _l2Target) public {
        require(l2Target == address(0));
        l2Target = _l2Target;
    }

    /// @notice Returns whether the rate has changed since it was last submitted
    function rateStale() external view returns (bool) {
        return rate() != lastRate;
    }

    /// @notice Returns the calculated rETH exchange rate
    function rate() public view returns (uint256) {
        // Retrieve the inputs from RocketNetworkBalances and calculate the rate
        RocketNetworkBalancesInterface rocketNetworkBalances = RocketNetworkBalancesInterface(rocketStorage.getAddress(rocketNetworkBalancesKey));
        uint256 supply = rocketNetworkBalances.getTotalRETHSupply();
        if (supply == 0) {
            return 0;
        }
        return 1 ether * rocketNetworkBalances.getTotalETHBalance() / supply;
    }

    /// @notice Submits the current rETH exchange rate to the Arbitrum cross domain messenger contract
    /// @param _maxSubmissionCost Max gas deducted from user's L2 balance to cover base submission fee
    /// @param _gasLimit Max gas deducted from user's L2 balance to cover L2 execution
    /// @param _gasPriceBid price bid for L2 execution
    function submitRate(uint256 _maxSubmissionCost, uint256 _gasLimit, uint256 _gasPriceBid) external payable {
        lastRate = rate();
        // Send the cross chain message
        bytes memory data = abi.encodeWithSignature('updateRate(uint256)', lastRate);
        inbox.createRetryableTicket{value: msg.value}(
            l2Target,           // Target address
            0,                  // Call value
            _maxSubmissionCost, // Max submission cost
            msg.sender,         // Fee refund address on L2
            msg.sender,         // Value refund on L2
            _gasLimit,          // Max gas
            _gasPriceBid,       // Gas price bid
            data
        );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "@arbitrum/nitro-contracts/src/libraries/AddressAliasHelper.sol";

/// @author Kane Wallmann (Rocket Pool)
/// @notice Receives updates from L1 on the canonical rETH exchange rate
contract RocketArbitrumPriceOracle {
    // Events
    event RateUpdated(uint256 rate);

    /// @notice The rETH exchange rate in the form of how much ETH 1 rETH is worth
    uint256 public rate;

    /// @notice The timestamp of the block in which the rate was last updated
    uint256 public lastUpdated;

    /// @notice Should be set to the address of the messenger on L1
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function setOwner(address _newOwner) external {
        require(msg.sender == owner, "Not owner");
        owner = _newOwner;
    }

    /// @notice Called by the messenger contract on L1 to update the exchange rate
    function updateRate(uint256 _newRate) external {
        // Only allow calls from self
        require(msg.sender == AddressAliasHelper.applyL1ToL2Alias(owner));
        // Update state
        rate = _newRate;
        lastUpdated = block.timestamp;
        // Emit event
        emit RateUpdated(_newRate);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "./RocketArbitrumPriceOracle.sol";
import "./interfaces/balancer/IRateProvider.sol";

/// @author Kane Wallmann (Rocket Pool)
/// @notice Implements Balancer's IRateProvider interface
contract RocketBalancerRateProvider is IRateProvider {
    RocketArbitrumPriceOracle immutable oracle;

    constructor(RocketArbitrumPriceOracle _oracle) {
        oracle = _oracle;
    }

    function getRate() external override view returns (uint256) {
        return oracle.rate();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

interface IRateProvider {
    function getRate() external view returns (uint256);
}