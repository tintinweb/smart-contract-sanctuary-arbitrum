// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./interfaces/TypeAndVersionInterface.sol";
import "./ConfirmedOwner.sol";

// defines some interfaces for type safety and reduces encoding/decoding
// does not use the full interfaces intentionally because the requester only uses a fraction of them
interface IAggregatorProxy {
  function aggregator() external view returns (address);
}

interface IOffchainAggregator {
  function requestNewRound() external returns (uint80);
}

/**
 * @notice The heartbeat requester will maintain a mapping from allowed callers to corresponding proxies. When requested
 *         by eligible caller, it will call a proxy for an aggregator address and request a new round. The aggregator
 *         is gated by permissions and this requester address needs to be whitelisted.
 */
contract HeartbeatRequester is TypeAndVersionInterface, ConfirmedOwner {
  event HeartbeatPermitted(address indexed permittedCaller, address newProxy, address oldProxy);
  event HeartbeatRemoved(address indexed permittedCaller, address removedProxy);

  error HeartbeatNotPermitted();

  mapping(address => IAggregatorProxy) internal s_heartbeatList;

  /**
   * @notice versions:
   * - HeartbeatRequester 1.0.0: The requester fetches the latest aggregator address from proxy, and request a new round
   *                             using the aggregator address.
   */
  string public constant override typeAndVersion = "HeartbeatRequester 1.0.0";

  constructor() ConfirmedOwner(msg.sender) {}

  /**
   * @notice adds a permitted caller and proxy combination.
   * @param permittedCaller the permitted caller
   * @param proxy the proxy corresponding to this caller
   */
  function permitHeartbeat(address permittedCaller, IAggregatorProxy proxy) external onlyOwner {
    address oldProxy = address(s_heartbeatList[permittedCaller]);
    s_heartbeatList[permittedCaller] = proxy;
    emit HeartbeatPermitted(permittedCaller, address(proxy), oldProxy);
  }

  /**
   * @notice removes a permitted caller and proxy combination.
   * @param permittedCaller the permitted caller
   */
  function removeHeartbeat(address permittedCaller) external onlyOwner {
    address removedProxy = address(s_heartbeatList[permittedCaller]);
    delete s_heartbeatList[permittedCaller];
    emit HeartbeatRemoved(permittedCaller, removedProxy);
  }

  /**
   * @notice fetches aggregator address from proxy and requests a new round.
   * @param proxy the proxy address
   */
  function getAggregatorAndRequestHeartbeat(address proxy) external {
    IAggregatorProxy proxyInterface = s_heartbeatList[msg.sender];
    if (address(proxyInterface) != proxy) revert HeartbeatNotPermitted();

    IOffchainAggregator aggregator = IOffchainAggregator(proxyInterface.aggregator());
    aggregator.requestNewRound();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract TypeAndVersionInterface {
  function typeAndVersion() external pure virtual returns (string memory);
}