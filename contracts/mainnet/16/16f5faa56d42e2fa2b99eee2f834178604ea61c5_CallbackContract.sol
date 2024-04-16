// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.23;

import {ConfirmedOwner} from "chainlink/src/v0.8/shared/access/ConfirmedOwner.sol";


contract CallbackContract is ConfirmedOwner {

    event fulfilledRequestId(bytes32 requestId);
    event fulfilledDrawCid(bytes32 requestId, string cid, bytes err);
    event fulfilledDrawWinners(string cid);


    constructor() ConfirmedOwner(msg.sender) {

    }

    function deployDraw(address deployerAddress, string[] memory args) external onlyOwner returns (bytes32 requestId) {
        requestId = Deployer(deployerAddress).deployDraw(args);
        emit fulfilledRequestId(requestId);
        return requestId;
    }

    function fulfillDrawCid(bytes32 requestId, string memory cid, bytes memory err) external returns (string memory) {
        emit fulfilledDrawCid(requestId, cid, err);
        return cid;
    }

    function fulfillDrawWinners(string memory cid) external returns (string memory) {
        emit fulfilledDrawWinners(cid);
        return cid;
    }
   
}

interface Deployer {
    function deployDraw(string[] memory args) external returns (bytes32 requestId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ConfirmedOwnerWithProposal} from "./ConfirmedOwnerWithProposal.sol";

/// @title The ConfirmedOwner contract
/// @notice A contract with helpers for basic contract ownership.
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnable} from "../interfaces/IOwnable.sol";

/// @title The ConfirmedOwner contract
/// @notice A contract with helpers for basic contract ownership.
contract ConfirmedOwnerWithProposal is IOwnable {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    // solhint-disable-next-line custom-errors
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /// @notice Allows an owner to begin transferring ownership to a new address.
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /// @notice Allows an ownership transfer to be completed by the recipient.
  function acceptOwnership() external override {
    // solhint-disable-next-line custom-errors
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /// @notice Get the current owner
  function owner() public view override returns (address) {
    return s_owner;
  }

  /// @notice validate, transfer ownership, and emit relevant events
  function _transferOwnership(address to) private {
    // solhint-disable-next-line custom-errors
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /// @notice validate access
  function _validateOwnership() internal view {
    // solhint-disable-next-line custom-errors
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /// @notice Reverts if called by anyone other than the contract owner.
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOwnable {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}