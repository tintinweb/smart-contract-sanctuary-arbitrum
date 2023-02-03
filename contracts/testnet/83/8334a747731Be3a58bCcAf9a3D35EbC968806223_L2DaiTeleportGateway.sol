// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.6.11;
pragma experimental ABIEncoderV2;

import {TeleportGUID, TeleportGUIDHelper} from "../common/TeleportGUID.sol";
import {IL1TeleportGateway, IL2TeleportGateway} from "../common/TeleportInterfaces.sol";
import "./L2CrossDomainEnabled.sol";

interface Mintable {
  function mint(address usr, uint256 wad) external;

  function burn(address usr, uint256 wad) external;
}

contract L2DaiTeleportGateway is L2CrossDomainEnabled, IL2TeleportGateway {
  // --- Auth ---
  mapping(address => uint256) public wards;

  function rely(address usr) external auth {
    wards[usr] = 1;
    emit Rely(usr);
  }

  function deny(address usr) external auth {
    wards[usr] = 0;
    emit Deny(usr);
  }

  modifier auth() {
    require(wards[msg.sender] == 1, "L2DaiTeleportGateway/not-authorized");
    _;
  }

  address public immutable override l2Token;
  address public immutable override l1TeleportGateway;
  bytes32 public immutable override domain;
  uint256 public isOpen = 1;
  uint80 public nonce;
  mapping(bytes32 => uint256) public validDomains;
  mapping(bytes32 => uint256) public batchedDaiToFlush;

  event Closed();
  event Rely(address indexed usr);
  event Deny(address indexed usr);
  event File(bytes32 indexed what, bytes32 indexed domain, uint256 data);

  function _add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x);
  }

  constructor(
    address _l2Token,
    address _l1TeleportGateway,
    bytes32 _domain
  ) public {
    wards[msg.sender] = 1;
    emit Rely(msg.sender);

    l2Token = _l2Token;
    l1TeleportGateway = _l1TeleportGateway;
    domain = _domain;
  }

  function close() external auth {
    isOpen = 0;

    emit Closed();
  }

  function file(
    bytes32 what,
    bytes32 domain,
    uint256 data
  ) external auth {
    if (what == "validDomains") {
      require(data <= 1, "L2DaiTeleportGateway/invalid-data");

      validDomains[domain] = data;
    } else {
      revert("L2DaiTeleportGateway/file-unrecognized-param");
    }
    emit File(what, domain, data);
  }

  function initiateTeleport(
    bytes32 targetDomain,
    address receiver,
    uint128 amount
  ) external override {
    return
      _initiateTeleport(targetDomain, TeleportGUIDHelper.addressToBytes32(receiver), amount, 0);
  }

  function initiateTeleport(
    bytes32 targetDomain,
    address receiver,
    uint128 amount,
    address operator
  ) external override {
    return
      _initiateTeleport(
        targetDomain,
        TeleportGUIDHelper.addressToBytes32(receiver),
        amount,
        TeleportGUIDHelper.addressToBytes32(operator)
      );
  }

  function initiateTeleport(
    bytes32 targetDomain,
    bytes32 receiver,
    uint128 amount,
    bytes32 operator
  ) external override {
    return _initiateTeleport(targetDomain, receiver, amount, operator);
  }

  function _initiateTeleport(
    bytes32 targetDomain,
    bytes32 receiver,
    uint128 amount,
    bytes32 operator
  ) private {
    // Disallow initiating new teleport transfer if bridge is closed
    require(isOpen == 1, "L2DaiTeleportGateway/closed");

    // Disallow initiating new teleport transfer if targetDomain has not been whitelisted
    require(validDomains[targetDomain] == 1, "L2DaiTeleportGateway/invalid-domain");

    TeleportGUID memory teleport = TeleportGUID({
      sourceDomain: domain,
      targetDomain: targetDomain,
      receiver: receiver,
      operator: operator,
      amount: amount,
      nonce: nonce++,
      timestamp: uint48(block.timestamp)
    });

    batchedDaiToFlush[targetDomain] = _add(batchedDaiToFlush[targetDomain], amount);
    Mintable(l2Token).burn(msg.sender, amount);

    bytes memory message = abi.encodeWithSelector(
      IL1TeleportGateway.finalizeRegisterTeleport.selector,
      teleport
    );
    sendTxToL1(msg.sender, l1TeleportGateway, message);

    emit TeleportInitialized(teleport);
  }

  function flush(bytes32 targetDomain) external override {
    // We do not check for valid domain because previously valid domains still need their DAI flushed
    uint256 daiToFlush = batchedDaiToFlush[targetDomain];
    require(daiToFlush > 0, "L2DaiTeleportGateway/zero-dai-flush");

    batchedDaiToFlush[targetDomain] = 0;

    bytes memory message = abi.encodeWithSelector(
      IL1TeleportGateway.finalizeFlush.selector,
      targetDomain,
      daiToFlush
    );
    sendTxToL1(msg.sender, l1TeleportGateway, message);

    emit Flushed(targetDomain, daiToFlush);
  }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.6.11;

// Standard Maker Teleport GUID
struct TeleportGUID {
  bytes32 sourceDomain;
  bytes32 targetDomain;
  bytes32 receiver;
  bytes32 operator;
  uint128 amount;
  uint80 nonce;
  uint48 timestamp;
}

library TeleportGUIDHelper {
  function addressToBytes32(address addr) internal pure returns (bytes32) {
    return bytes32(uint256(uint160(addr)));
  }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.6.11;
pragma experimental ABIEncoderV2;

import {TeleportGUID} from "./TeleportGUID.sol";

interface IL1TeleportRouter {
  function requestMint(
    TeleportGUID calldata teleportGUID,
    uint256 maxFeePercentage,
    uint256 operatorFee
  ) external returns (uint256 postFeeAmount, uint256 totalFee);

  function settle(bytes32 targetDomain, uint256 batchedDaiToFlush) external;
}

interface IL1TeleportGateway {
  function l1Token() external view returns (address);

  function l1Escrow() external view returns (address);

  function l1TeleportRouter() external view returns (IL1TeleportRouter);

  function l2TeleportGateway() external view returns (address);

  function finalizeFlush(bytes32 targetDomain, uint256 daiToFlush) external;

  function finalizeRegisterTeleport(TeleportGUID calldata teleport) external;
}

interface IL2TeleportGateway {
  event TeleportInitialized(TeleportGUID teleport);
  event Flushed(bytes32 indexed targetDomain, uint256 dai);

  function l2Token() external view returns (address);

  function l1TeleportGateway() external view returns (address);

  function domain() external view returns (bytes32);

  function initiateTeleport(
    bytes32 targetDomain,
    address receiver,
    uint128 amount
  ) external;

  function initiateTeleport(
    bytes32 targetDomain,
    address receiver,
    uint128 amount,
    address operator
  ) external;

  function initiateTeleport(
    bytes32 targetDomain,
    bytes32 receiver,
    uint128 amount,
    bytes32 operator
  ) external;

  function flush(bytes32 targetDomain) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.6.11;

import "../arbitrum/ArbSys.sol";

abstract contract L2CrossDomainEnabled {
  event TxToL1(address indexed from, address indexed to, uint256 indexed id, bytes data);

  function sendTxToL1(
    address user,
    address to,
    bytes memory data
  ) internal returns (uint256) {
    // note: this method doesn't support sending ether to L1 together with a call
    uint256 id = ArbSys(address(100)).sendTxToL1(to, data);

    emit TxToL1(user, to, id, data);

    return id;
  }

  modifier onlyL1Counterpart(address l1Counterpart) {
    require(msg.sender == applyL1ToL2Alias(l1Counterpart), "ONLY_COUNTERPART_GATEWAY");
    _;
  }

  uint160 constant offset = uint160(0x1111000000000000000000000000000000001111);

  // l1 addresses are transformed durng l1->l2 calls
  function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
    l2Address = address(uint160(l1Address) + offset);
  }
}

pragma solidity >=0.4.21 <0.7.0;

/**
 * @title Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality.
 */
interface ArbSys {
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
  function withdrawEth(address destination) external payable returns (uint256);

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
  function getTransactionCount(address account) external view returns (uint256);

  /**
   * @notice get the value of target L2 storage slot
   * This function is only callable from address 0 to prevent contracts from being able to call it
   * @param account target account
   * @param index target index of storage slot
   * @return stotage value for the given account at the given index
   */
  function getStorageAt(address account, uint256 index) external view returns (uint256);

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