/**
 *Submitted for verification at arbiscan.io on 2022-03-03
*/

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

interface IMessageProvider {
  event InboxMessageDelivered(uint256 indexed messageNum, bytes data);

  event InboxMessageDeliveredFromOrigin(uint256 indexed messageNum);
}

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

  function createRetryableTicketNoRefundAliasRewrite(
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

  function bridge() external view returns (address);

  function pauseCreateRetryables() external;

  function unpauseCreateRetryables() external;

  function startRewriteAddress() external;

  function stopRewriteAddress() external;
}

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
}

interface IOutbox {
  event OutboxEntryCreated(
    uint256 indexed batchNum,
    uint256 outboxEntryIndex,
    bytes32 outputRoot,
    uint256 numInBatch
  );
  event OutBoxTransactionExecuted(
    address indexed destAddr,
    address indexed l2Sender,
    uint256 indexed outboxEntryIndex,
    uint256 transactionIndex
  );

  function l2ToL1Sender() external view returns (address);

  function l2ToL1Block() external view returns (uint256);

  function l2ToL1EthBlock() external view returns (uint256);

  function l2ToL1Timestamp() external view returns (uint256);

  function l2ToL1BatchNum() external view returns (uint256);

  function l2ToL1OutputId() external view returns (bytes32);

  function processOutgoingMessages(bytes calldata sendsData, uint256[] calldata sendLengths)
    external;

  function outboxEntryExists(uint256 batchNum) external view returns (bool);
}

abstract contract L1CrossDomainEnabled {
  IInbox public immutable inbox;

  event TxToL2(address indexed from, address indexed to, uint256 indexed seqNum, bytes data);

  constructor(address _inbox) public {
    inbox = IInbox(_inbox);
  }

  modifier onlyL2Counterpart(address l2Counterpart) {
    // a message coming from the counterpart gateway was executed by the bridge
    address bridge = inbox.bridge();
    require(msg.sender == bridge, "NOT_FROM_BRIDGE");

    // and the outbox reports that the L2 address of the sender is the counterpart gateway
    address l2ToL1Sender = IOutbox(IBridge(bridge).activeOutbox()).l2ToL1Sender();
    require(l2ToL1Sender == l2Counterpart, "ONLY_COUNTERPART_GATEWAY");
    _;
  }

  function sendTxToL2(
    address target,
    address user,
    uint256 maxSubmissionCost,
    uint256 maxGas,
    uint256 gasPriceBid,
    bytes memory data
  ) internal returns (uint256) {
    uint256 seqNum = inbox.createRetryableTicket{value: msg.value}(
      target,
      0, // we always assume that l2CallValue = 0
      maxSubmissionCost,
      user,
      user,
      maxGas,
      gasPriceBid,
      data
    );
    emit TxToL2(user, target, seqNum, data);
    return seqNum;
  }

  function sendTxToL2NoAliasing(
    address target,
    address user,
    uint256 l1CallValue,
    uint256 maxSubmissionCost,
    uint256 maxGas,
    uint256 gasPriceBid,
    bytes memory data
  ) internal returns (uint256) {
    uint256 seqNum = inbox.createRetryableTicketNoRefundAliasRewrite{value: l1CallValue}(
      target,
      0, // we always assume that l2CallValue = 0
      maxSubmissionCost,
      user,
      user,
      maxGas,
      gasPriceBid,
      data
    );
    emit TxToL2(user, target, seqNum, data);
    return seqNum;
  }
}

// Standard Maker Wormhole GUID
struct WormholeGUID {
  bytes32 sourceDomain;
  bytes32 targetDomain;
  bytes32 receiver;
  bytes32 operator;
  uint128 amount;
  uint80 nonce;
  uint48 timestamp;
}

library WormholeGUIDHelper {
  function addressToBytes32(address addr) internal pure returns (bytes32) {
    return bytes32(uint256(uint160(addr)));
  }
}

interface WormholeRouter {
  function requestMint(
    WormholeGUID calldata wormholeGUID,
    uint256 maxFeePercentage,
    uint256 operatorFee
  ) external returns (uint256 postFeeAmount, uint256 totalFee);

  function settle(bytes32 targetDomain, uint256 batchedDaiToFlush) external;
}

interface TokenLike {
  function approve(address, uint256) external returns (bool);

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) external returns (bool success);
}

contract L1DaiWormholeGateway is L1CrossDomainEnabled {
  address public immutable l1Token;
  address public immutable l2DaiWormholeGateway;
  address public immutable escrow;
  WormholeRouter public immutable wormholeRouter;

  constructor(
    address _l1Token,
    address _l2DaiWormholeGateway,
    address _inbox,
    address _escrow,
    address _wormholeRouter
  ) public L1CrossDomainEnabled(_inbox) {
    l1Token = _l1Token;
    l2DaiWormholeGateway = _l2DaiWormholeGateway;
    escrow = _escrow;
    wormholeRouter = WormholeRouter(_wormholeRouter);
    // Approve the router to pull DAI from this contract during settle() (after the DAI has been pulled by this contract from the escrow)
    TokenLike(_l1Token).approve(_wormholeRouter, type(uint256).max);
  }

  function finalizeFlush(bytes32 targetDomain, uint256 daiToFlush)
    external
    onlyL2Counterpart(l2DaiWormholeGateway)
  {
    // Pull DAI from the escrow to this contract
    TokenLike(l1Token).transferFrom(escrow, address(this), daiToFlush);
    // The router will pull the DAI from this contract
    wormholeRouter.settle(targetDomain, daiToFlush);
  }

  function finalizeRegisterWormhole(WormholeGUID calldata wormhole)
    external
    onlyL2Counterpart(l2DaiWormholeGateway)
  {
    wormholeRouter.requestMint(wormhole, 0, 0);
  }
}

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

interface Mintable {
  function mint(address usr, uint256 wad) external;

  function burn(address usr, uint256 wad) external;
}

contract L2DaiWormholeGateway is L2CrossDomainEnabled {
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
    require(wards[msg.sender] == 1, "L2DaiWormholeGateway/not-authorized");
    _;
  }

  address public immutable l2Token;
  address public immutable l1DaiWormholeGateway;
  bytes32 public immutable domain;
  uint256 public isOpen = 1;
  uint80 public nonce;
  mapping(bytes32 => uint256) public validDomains;
  mapping(bytes32 => uint256) public batchedDaiToFlush;

  event Closed();
  event Rely(address indexed usr);
  event Deny(address indexed usr);
  event File(bytes32 indexed what, bytes32 indexed domain, uint256 data);
  event WormholeInitialized(WormholeGUID wormhole);
  event Flushed(bytes32 indexed targetDomain, uint256 dai);

  constructor(
    address _l2Token,
    address _l1DaiWormholeGateway,
    bytes32 _domain
  ) public {
    wards[msg.sender] = 1;
    emit Rely(msg.sender);

    l2Token = _l2Token;
    l1DaiWormholeGateway = _l1DaiWormholeGateway;
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
      require(data <= 1, "L2DaiWormholeGateway/invalid-data");

      validDomains[domain] = data;
    } else {
      revert("L2DaiWormholeGateway/file-unrecognized-param");
    }
    emit File(what, domain, data);
  }

  function initiateWormhole(
    bytes32 targetDomain,
    address receiver,
    uint128 amount
  ) external {
    return
      _initiateWormhole(targetDomain, WormholeGUIDHelper.addressToBytes32(receiver), amount, 0);
  }

  function initiateWormhole(
    bytes32 targetDomain,
    address receiver,
    uint128 amount,
    address operator
  ) external {
    return
      _initiateWormhole(
        targetDomain,
        WormholeGUIDHelper.addressToBytes32(receiver),
        amount,
        WormholeGUIDHelper.addressToBytes32(operator)
      );
  }

  function initiateWormhole(
    bytes32 targetDomain,
    bytes32 receiver,
    uint128 amount,
    bytes32 operator
  ) external {
    return _initiateWormhole(targetDomain, receiver, amount, operator);
  }

  function _initiateWormhole(
    bytes32 targetDomain,
    bytes32 receiver,
    uint128 amount,
    bytes32 operator
  ) private {
    // Disallow initiating new wormhole transfer if bridge is closed
    require(isOpen == 1, "L2DaiWormholeGateway/closed");

    // Disallow initiating new wormhole transfer if targetDomain has not been whitelisted
    require(validDomains[targetDomain] == 1, "L2DaiWormholeGateway/invalid-domain");

    WormholeGUID memory wormhole = WormholeGUID({
      sourceDomain: domain,
      targetDomain: targetDomain,
      receiver: receiver,
      operator: operator,
      amount: amount,
      nonce: nonce++,
      timestamp: uint48(block.timestamp)
    });

    batchedDaiToFlush[targetDomain] += amount;
    Mintable(l2Token).burn(msg.sender, amount);

    bytes memory message = abi.encodeWithSelector(
      L1DaiWormholeGateway.finalizeRegisterWormhole.selector,
      wormhole
    );
    sendTxToL1(msg.sender, l1DaiWormholeGateway, message);

    emit WormholeInitialized(wormhole);
  }

  function flush(bytes32 targetDomain) external {
    // We do not check for valid domain because previously valid domains still need their DAI flushed
    uint256 daiToFlush = batchedDaiToFlush[targetDomain];
    require(daiToFlush > 0, "L2DaiWormholeGateway/zero-dai-flush");

    batchedDaiToFlush[targetDomain] = 0;

    bytes memory message = abi.encodeWithSelector(
      L1DaiWormholeGateway.finalizeFlush.selector,
      targetDomain,
      daiToFlush
    );
    sendTxToL1(msg.sender, l1DaiWormholeGateway, message);

    emit Flushed(targetDomain, daiToFlush);
  }
}